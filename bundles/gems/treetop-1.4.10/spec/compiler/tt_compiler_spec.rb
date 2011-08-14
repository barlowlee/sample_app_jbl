require 'digest/sha1'
require 'tmpdir'

# ensure the Kernel.system and Kernel.open's always use the correct tt and
# Treetop library versions, not a previously installed gem
ENV['PATH'] = File.expand_path(File.dirname(__FILE__) + '../../../bin' +
                              File::PATH_SEPARATOR + ENV['PATH'])
$LOAD_PATH.unshift(File.expand_path('../../../../lib', __FILE__))

describe "The 'tt' comand line compiler" do
  before(:each) do
    @tmpdir = Dir.tmpdir
  end

  context 'when processing a single grammar file' do
    before(:each) do
      # create a fresh but dumb grammar file for each example
      @test_base = "dumb-#{rand(1000)}"
      @test_path = "#{@tmpdir}/#{@test_base}"
      @test_grammar = "#{@test_path}.tt"
      @test_ruby = "#{@test_path}.rb"
      File.open(@test_grammar, 'w+') do |f|
        f.print("grammar Dumb\n")
        f.print("end\n")
      end unless File.exists?(@test_grammar)
    end

    after(:each) do
      # cleanup test grammar and parser output files
      File.delete(@test_grammar) if File.exists?(@test_grammar)
      File.delete(@test_ruby) if File.exists?(@test_ruby)
    end

    it 'can compile a grammar file' do
      # puts %q{emulate 'tt dumb.tt'}
      system("ruby -S tt #{@test_grammar}").should be_true

      File.exists?(@test_ruby).should be_true
      File.zero?(@test_ruby).should_not be_true
    end

    it 'can compile a relative pathed grammar file' do
      dir = File.basename(File.expand_path(File.dirname(@test_grammar)))

      # puts %q{emulate 'tt "../<current_dir>/dumb.tt"'}
      system("cd #{@tmpdir}/..; ruby -S tt \"./#{dir}/#{@test_base}.tt\"").should be_true

      File.exists?(@test_ruby).should be_true
      File.zero?(@test_ruby).should_not be_true
    end

    it 'can compile an absolute pathed grammar file' do
      # puts %q{emulate 'tt "/path/to/dumb.tt"'}
      system("ruby -S tt \"#{File.expand_path(@test_grammar)}\"").should be_true

      File.exists?(@test_ruby).should be_true
      File.zero?(@test_ruby).should_not be_true
    end

    it 'can compile without explicit file extensions' do
      # puts %q{emulate 'tt dumb'}
      system("ruby -S tt #{@test_path}").should be_true

      File.exists?(@test_ruby).should be_true
      File.zero?(@test_ruby).should_not be_true
    end

    it 'skips nonexistent grammar file without failing or creating bogus output' do
      # puts %q{emulate 'tt dumb.bad'}
      Kernel.open("|ruby -S tt #{@test_base}.bad") do |io|
        (io.read =~ /ERROR.*?not exist.*?continuing/).should_not be_nil
      end

      File.exists?("#{@test_base}.rb").should be_false
    end

    it 'can compile to a specified parser source file' do
      # puts %q{emulate 'tt -o my_dumb_test_parser.rb dumb'}
      pf = "#{@tmpdir}/my_dumb_test_parser.rb"
      begin
        system("ruby -S tt -o #{pf} #{@test_path}").should be_true

        File.exists?(pf).should be_true
        File.zero?(pf).should_not be_true
      ensure
        File.delete(pf) if File.exists?(pf)
      end
    end

    it 'by default, does not overwrite an existing file without an autogenerated header' do
      # puts %q{emulate 'tt -o must_save_parser.rb dumb'}
      pf = "#{@tmpdir}/must_save_parser.rb"
      begin
        system("ruby -S tt -o #{pf} #{@test_path}").should be_true

        File.exists?(pf).should be_true
        File.zero?(pf).should_not be_true

        # Modify the file and make sure it remains unchanged:
        File.open(pf, "r+") { |f| f.write("# Changed...") }
        orig_file_hash = Digest::SHA1.hexdigest(File.read(pf))

        Kernel.open("|ruby -S tt -o #{pf} #{@test_path}") do |io|
          (io.read =~ /ERROR.*?already exists.*?skipping/).should_not be_nil
        end

        Digest::SHA1.hexdigest(File.read(pf)).should == orig_file_hash
      ensure
        File.delete(pf) if File.exists?(pf)
      end
    end

    it 'by default, overwrites a changed file with an intact autogenerated header' do
      # puts %q{emulate 'tt -o must_save_parser.rb dumb'}
      pf = "#{@tmpdir}/must_save_parser.rb"
      begin
        system("ruby -S tt -o #{pf} #{@test_path}").should be_true

        File.exists?(pf).should be_true
        File.zero?(pf).should_not be_true
        orig_file_hash = Digest::SHA1.hexdigest(File.read(pf))

        # Modify the file and make sure it gets reverted:
        File.open(pf, "r+") { |f| f.gets; f.write("#") }

        system("ruby -S tt -o #{pf} #{@test_path}").should be_true
        Digest::SHA1.hexdigest(File.read(pf)).should == orig_file_hash
      ensure
        File.delete(pf) if File.exists?(pf)
      end
    end

    it 'can be forced to overwrite existing file #{@test_path}' do
      pf = "#{@test_path}.rb"
      system("echo some junk >#{pf}").should be_true

      File.exists?(pf).should be_true
      File.zero?(pf).should_not be_true
      orig_file_hash = Digest::SHA1.hexdigest(File.read(pf))

      system("ruby -S tt -f #{@test_path}").should be_true
      Digest::SHA1.hexdigest(File.read(pf)).should_not == orig_file_hash
    end

  end

  context 'when processing multiple grammar files' do

    before(:each) do
      # provide fresh but dumb grammar files for each test
      @test_bases = []
      @test_grammars = []

      %w[dumb1 dumb2].each do |e|
        base = "#{@tmpdir}/#{e}-#{rand(1000)}"
        grammar_file = "#{base}.tt"
        @test_bases << base
        @test_grammars << grammar_file

        File.open(grammar_file, 'w+') do |f|
          f.print("grammar #{e.capitalize}\n")
          f.print("end\n")
        end unless File.exists?(grammar_file)
      end
    end

    after(:each) do
      # cleanup test grammar and output parser files
      @test_grammars.each { |f| File.delete(f) if File.exists?(f) }
      @test_bases.each { |f| File.delete("#{f}.rb") if File.exists?("#{f}.rb") }
    end
 
    it 'can compile them in one invocation' do
      # puts %q{emulate 'tt dumb1.tt dumb2.tt'}
      system("ruby -S tt #{@test_grammars.join(' ')}").should be_true

      @test_bases.each do |f|
        pf = "#{f}.rb"
        File.exists?(pf).should be_true
        File.zero?(pf).should_not be_true
      end
    end

    it 'can compile them without explicit file extenstions' do
      # puts %q{emulate 'tt dumb1 dumb2'}
      system("ruby -S tt #{@test_bases.join(' ')}").should be_true

      @test_bases.each do |f|
        pf = "#{f}.rb"
        File.exists?(pf).should be_true
        File.zero?(pf).should_not be_true
      end
    end

    it 'can skip nonexistent and invalid extension named grammar files' do
      # puts %q{emulate 'tt not_here bad_ext.ttg dumb1 dumb2'}
      system("ruby -S tt not_here bad_ext.ttg #{@test_bases.join(' ')} >/dev/null 2>&1").should be_true

      File.exists?('not_here.rb').should_not be_true
      File.exists?('bad_ext.rb').should_not be_true

      @test_bases.each do |f|
        pf = "#{f}.rb"
        File.exists?(pf).should be_true
        File.zero?(pf).should_not be_true
      end
    end

    it 'can not specify an output file' do
      # puts %q{emulate 'tt -o my_bogus_test_parser.rb dumb1 dumb2'}
      pf = 'my_bogus_test_parser.rb'
      system("ruby -S tt -o #{pf} #{@test_bases.join(' ')} >/dev/null 2>&1").should be_false
      File.exists?(pf).should be_false
    end
  end

end
