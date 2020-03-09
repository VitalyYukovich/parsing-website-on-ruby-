require 'curb'
require 'nokogiri'
require 'csv'

class Parser
	def initialize(url, fileName)
		puts "Start parsing. Wait a few minuts "
		@url = url
		@urlsProduct = []
		@products = []
		@fileName = fileName
		@easy_options = {:follow_location => true}
		@multi_options = {:pipeline => Curl::CURLPIPE_HTTP1}
	end

	def getDoc(url)
		open_url = Curl::Easy.new(url)
		open_url.ssl_verify_peer = false
		open_url.perform
		Nokogiri::HTML(open_url.body_str)
	end

	def UrlsProduct
		urlsArray = []

		countPage = getDoc(@url).xpath("//div[@id='pagination_bottom']/ul/li/a/span")[-2].inner_html.to_i

		for i in 1..countPage do
			urlsArray.push(@url +'?p=' + i.to_s)
		end
		Curl::Multi.get(urlsArray, @easy_options, @multi_options) do|urlPageCategory|
			doc = getDoc(urlPageCategory.last_effective_url)
			doc.css('.lnk_view').each do |lnk_view|
				@urlsProduct.push(lnk_view['href'])
			end
		end
	end
	
	def InfoProduct
		i=1
		Curl::Multi.get(@urlsProduct, @easy_options, @multi_options) do|urlProduct|
			doc_product=getDoc(urlProduct.last_effective_url)
			name_product = doc_product.xpath('//*[@class="product_main_name"]').inner_html
			index_name_product=name_product.rindex('<br>')
			name_product=name_product[index_name_product+4..-1]
			pic_product = doc_product.xpath('//*[@id="bigpic"]')[0]['src']
			doc_product.xpath('//*[@class="attribute_radio_list"]/li').each do |info_product|
				weight = info_product.css('.radio_label').inner_html
				price_product = info_product.css('.price_comb').inner_html.split(' ').first.to_f
				puts i
				i+=1
				@products.push(
					Name: name_product + ' - ' + weight,
					Price: price_product,
					Picture: pic_product
				)
			end
		end
	end
	def parsing()
		CSV.open(@fileName + '.csv', "w") do |csv|
  			self.UrlsProduct
			self.InfoProduct
			@products.each do |product|
  				csv<<product.values
  			end
		end
	end
end


puts 'Введите ссылку категории'
url = gets.chomp.to_s
puts 'Введите имя файла'
fileName = gets.chomp.to_s
pars = Parser.new(url, fileName)
pars.parsing()

#ruby d:/homework/ruby/parser.rb