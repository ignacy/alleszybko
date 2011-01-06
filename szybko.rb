# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require 'haml'
gem 'soap4r'
require 'soap/wsdlDriver'


require 'yaml'

before do
  content_type :html, 'charset' => 'utf-8'
end

def config
  YAML.load_file("config/allegro.yml")
end

helpers do
  def allegro_link(l, id)
    l = l.downcase.gsub(/ /, '-').gsub(/,/, "-").
      gsub(/\.|\(|\)|\:|\!|\[|\]|\"|\'|\/|\\|\>|\<|\{|\}|\@|\#/, "").
      gsub(/Ł|ł/, "l").
      gsub(/Ż|ż|ź|Ź/, "z").
      gsub(/ó/, "o").
      gsub(/Ó/, "o").
      gsub(/ś|Ś/, "s").
      gsub(/Ć|ć/, "c").
      gsub(/ą|Ą/, "a").
      gsub(/Ę|ę/, "e")

    "http://allegro.pl/#{l}-i#{id}.html"
  end

  # def cena(sr)
  #   if sr["s-it-buy-now-price"] && (sr["s-it-buy-now-price"] != 0.0)
  #     "<b> #{sr["s-it-buy-now-price"].to_i} </b> <small> Kup teraz </small>"
  #   else
  #     "<b> #{sr["s-it-price"].to_i} </b> <small> Aktualna cena </small> "
  #   end
  # end
  def cena(sr)
    "<b> #{sr["s-it-buy-now-price"].to_i} </b>zł."
  end
end


get '/' do
  haml :index
end

post '/results' do
  client = SOAP::WSDLDriverFactory.new( 'http://webapi.allegro.pl/uploader.php?wsdl' ).create_rpc_driver
  @key = client.doQuerySysStatus(1, 1, config['api_key']).last
  @session = client.doLogin(config['login'], config['password'], 1, config['api_key'], @key).first
  @search_results = client.doSearch(@session, { "search-string" => params[:query], "search-offset" => 2, "search-limit" => 100, "search-options" => 8, "search-order" => 4, "search-order-type" => 0})[2]
  @query = params[:query] || ""
  haml :results
end

get '/about' do
  haml :about
end
