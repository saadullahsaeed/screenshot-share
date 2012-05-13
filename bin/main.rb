#!/usr/bin/env ruby -KU

require 'rubygems'
require 'fssm'
require 'json'
require 'curb'
require 'crack/json'
require 'ruby-growl'
require 'yaml'


def log(text)
  
  puts "#{text}"
end


def copy_to_clipboard(text)
  
  IO.popen('pbcopy', 'r+') { |clipboard| clipboard.puts text }
end


def notify_growl(file, url)
  
  system "growl -H 127.0.0.1 -m \"File: #{file} has been uploaded to: #{url}\" --sticky"
end


def upload_to_imgur(base, file)
  
  file_path = "#{base}/#{file}"
  
  log "Attempting to upload #{file_path}"
  
  begin

    c = Curl::Easy.new("http://imgur.com/api/upload.json")
    c.multipart_form_post = true
    
    if $config['imgur_session'] then
      c.cookies = "IMGURSESSION="+$config['imgur_session']
    end
    
    c.http_post(Curl::PostField.content('key', $config['key']), Curl::PostField.file('image', file_path))
    response = Crack::JSON.parse c.body_str
    image_url = response["rsp"]["image"]["original_image"]
    
    log "Image Uploaded to: #{image_url}"
    copy_to_clipboard image_url
    
    notify_growl file, image_url
    
  rescue Exception => exception
    puts test_exception.message
  end
  
end


config_file = ARGV[0]
if not config_file then abort "Usage: main.rb /path/to/config.yaml" end

$config = YAML.load(File.read(config_file))

puts "Listening now"
FSSM.monitor($config['listen_to_dir'], ['**/*.png']) do
  create { |base, relative, type| upload_to_imgur base, relative }
end

exit 0