# A sample Guardfile
# More info at https://github.com/guard/guard#readme

# Add files and commands to this file, like the example:
#   watch(%r{file/path}) { `command(s)` }
#
#guard 'shell' do
#  watch(/(.*)/) {|m| `tail #{m[0]}` }
#end
guard 'shell' do
  watch(/(.*)/) do |m|
    if system("git ls-files --exclude-standard -d -o -m | egrep '.' > /dev/null")

      system('git add -A')
      system("git commit -m 'WIP: #{m|0|}'")

    end
  end
end


