SimpleCov.start do
  project_name 'estore'

  # Filter out the following files
  add_filter '/spec/'
  add_filter '/gems/'
  add_filter '/config/'

  require 'coveralls'

  formatters = [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]

  if RUBY_ENGINE == 'rbx'
    require 'codeclimate-test-reporter'
    formatters << CodeClimate::TestReporter::Formatter
  end

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    *formatters
  ]
end
