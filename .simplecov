SimpleCov.start do
  project_name 'estore'

  # Filter out the following files
  add_filter '/spec/'
  add_filter '/gems/'
  add_filter '/config/'

  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    Coveralls::SimpleCov::Formatter,
    SimpleCov::Formatter::HTMLFormatter
  ]
end
