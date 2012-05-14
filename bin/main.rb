#!/usr/bin/env ruby -KU

require 'rubygems'
require 'fssm'
require 'crack/json'
require 'ruby-growl'
require 'yaml'
require 'oauth'


def log(text)
  
  puts "#{text}"
end


def copy_to_clipboard(text)
  
  IO.popen('pbcopy', 'r+') { |clipboard| clipboard.puts text }
end


def notify_growl(file, url)
  
  system "growl -H 127.0.0.1 -t \"Screenshot Uploaded\" -m \"File: #{file} has been uploaded to: #{url}\" --sticky"
end


def upload_to_imgur(base, file)
  
  file_path = "#{base}/#{file}"
  
  log "Attempting to upload #{file_path}"
  
  begin

    request_params = {
      :key => $config['key'],
      :image => Base64.encode64(File.read file_path),
      :type => 'base64'
    }
    
    response = $consumer.request(:post, '/account/images.json', $access_token, {}, request_params)
    #puts response.body
    result = Crack::JSON.parse response.body

    image_url = result["images"]["links"]["original"]
    log "Image Uploaded to: #{image_url}"
    
    copy_to_clipboard image_url
    notify_growl file, image_url
    
  rescue Exception => exception
    
    puts exception.message
  end
  
end


config_file = ARGV[0]
if not config_file then abort "Usage: main.rb /path/to/config.yaml" end

$config = YAML.load(File.read(config_file))

$consumer=OAuth::Consumer.new($config['consumer_key'], $config['consumer_secret'], {:site=>"https://api.imgur.com/2"})
$access_token = OAuth::AccessToken.from_hash($consumer, {:oauth_token=>$config['oauth_token'], :oauth_token_secret => $config['oauth_token_secret']})

puts "Listening now"
FSSM.monitor($config['listen_to_dir'], ['**/*.png']) do
  create { |base, relative, type| upload_to_imgur base, relative }
end

exit 0