rspec_base = File.expand_path(File.dirname(__FILE__) + '/../../rspec/lib')
$LOAD_PATH.unshift(rspec_base) if File.exist?(rspec_base)
require 'spec/rake/spectask'

namespace :spec do
  namespace :plugins do
    desc "Runs the examples for acts_as_authenticated_user"
    Spec::Rake::SpecTask.new(:acts_as_authenticated_user) do |t|
      t.spec_opts = ['--options', "\"#{RAILS_ROOT}/spec/spec.opts\""]
      t.spec_files = FileList['vendor/plugins/acts_as_authenticated_user/spec/**/*_spec.rb']
    end
  end
end
