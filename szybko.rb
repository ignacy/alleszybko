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
      gsub(/\.|\(|\)|\:|\!|\[|\]|\"|\'|\/|\\|\>|\<|\{|\}|\@|\#|\*|\_/, "").
      gsub(/Ł|ł/, "l").
      gsub(/Ż|ż|ź|Ź/, "z").
      gsub(/ó/, "o").
      gsub(/Ó/, "o").
      gsub(/ś|Ś/, "s").
      gsub(/Ć|ć/, "c").
      gsub(/ą|Ą/, "a").
      gsub(/Ę|ę/, "e").
      gsub(/Ń|ń/, "n")

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
  redirect '/' if params[:query] == ""

  client = SOAP::WSDLDriverFactory.new( 'http://webapi.allegro.pl/uploader.php?wsdl' ).create_rpc_driver
  @key = client.doQuerySysStatus(1, 1, config['api_key']).last
  @session = client.doLogin(config['login'], config['password'], 1, config['api_key'], @key).first

  @buy_now = !params[:buy_now].nil?
  @order = !params[:order].nil?

  @cena_od = (params[:zakres_od] == "") ? 0 : params[:zakres_od].to_i
  @cena_do = (params[:zakres_do] == "") ? 0 : params[:zakres_do].to_i


  @order_value = params[:order_by]

  if params[:order_by] == "price"
    order_by = 4
  else
    order_by = 1
  end

  if params[:query]
    options = @buy_now ? 8 : 0

    @search_results = client.doSearch(@session,
                                      { "search-string" => params[:query],
                                        "search-limit" => 100,
                                        "search-options" => options,
                                        "search-order" => order_by,
                                        "search-price-to" => Float(@cena_do),
                                        "search-price-from" => Float(@cena_od),
                                        "search-order-type" => @order ? 1 : 0})[2]
  end


  @query = params[:query] || ""
  haml :results
end

get '/about' do
  haml :about
end
