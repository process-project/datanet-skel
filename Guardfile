guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb') { "spec" }

  #guard api changes
  watch('api/datanet-skel/api.rb') { |m| 'spec/datanet-skel/api'}
  watch(%r{^api/datanet-skel/api_v(.+)\.rb}) { |m| "spec/datanet-skel/api/api_v#{m[1]}_spec.rb"}
end

guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end