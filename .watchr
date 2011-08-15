def growl
  title = "Watchr Test Results"
  image = $?.success? ? "~/.watchr/images/passed.png" : "~/.watchr/images/failed.png"
  message = $?.success? ? "success" : "failed"
  growlnotify = `which growlnotify`.chomp
  options = "-w -n Watchr --image '#{File.expand_path(image)}' -m '#{message}' '#{title}'"
  system %(#{growlnotify} #{options} &)
end

def run(cmd)
  puts cmd
  system(cmd)
end

def spec(file)
  if File.exists?(file)
    run("bundle exec rspec #{file}")
    growl
  else
    puts("Spec: #{file} does not exist.")
  end
end

def run_all_specs
#  run "bundle exec rake spec"
  growl
end

def run_suite
  system "clear"
  run_all_specs
end

watch("spec/.*/*_spec.rb") do |match|
  puts(match[0])
  spec(match[0])
end

watch("app/(.*/.*).rb") do |match|  # added #/controllers to make it ignore views
  puts(match[1])
  spec("spec/#{match[1]}_spec.rb")
end

@interrupted = false

# Ctrl-C
Signal.trap 'INT' do
  if @interrupted then
    @wants_to_quit = true
    abort("\n")
  else
    puts "Interrupt a second time to quit"
    @interrupted = true
    Kernel.sleep 1.5
    # raise Interrupt, nil # let the run loop catch it
    run_suite
  end
end
