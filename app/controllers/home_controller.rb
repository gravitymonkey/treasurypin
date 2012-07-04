class HomeController < ApplicationController
  require 'open-uri'
  require 'RMagick'
  require 's3'
  require 'uri'

  def index
  end

  def processUrl
	url = params[:url]
	doc = Nokogiri::HTML(open(url))

	title = doc.at_css("title").text

	maxCount = 0
	newImage = nil

	prepend = rand(10000000).to_s
	longrand = prepend + rand(10000000).to_s

	doc.xpath("//meta[@property='og:image']/@content").each do |attr|
  		if (maxCount < 8)
        		puts attr.value
        		image = MiniMagick::Image.open(attr.value)
        		image.write("tempimg/" + prepend + "_" + maxCount.to_s + ".jpg")
  		end
  		maxCount = maxCount + 1
	end

	w = 0
	t = 0

  
	while w < 4
        	img = Magick::Image.new(170 * 2, 135) {
                	self.background_color = 'white'
        	}
	
        	ilist = Magick::ImageList.new("tempimg/" + prepend + "_" + t.to_s + ".jpg", "tempimg/" + prepend + "_" + (t + 1).to_s + ".jpg")
        	img = ilist.append(false)

        	img.write("tempimg/" + prepend + "_" + w.to_s + "_pair.jpg")
        	w+=1
        	t+=2
  	end

  	ilist = Magick::ImageList.new("tempimg/" + prepend + "_0_pair.jpg", "tempimg/" + prepend + "_1_pair.jpg", "tempimg/" + prepend + "_2_pair.jpg", "tempimg/" + prepend + "_3_pair.jpg")
  	ximg = Magick::Image.new(170 * 2, 135 * 4)
  	ximg = ilist.append(true)

  	ximg.write("tempimg/" + prepend + "_final.jpg")


  	service = S3::Service.new(:access_key_id => "XXXXXXXXXXXXXXXXXXXX",
                          :secret_access_key => "XXXXXXXXXXXXXXXXXXXXX")
	bucket = service.bucket("treasurypin")
	@filename = longrand + ".jpg"
	new_object = bucket.objects.build("public/" + @filename)
	new_object.content = open("tempimg/" + prepend + "_final.jpg")
	new_object.content_type = "image/jpeg"
	new_object.acl = "public-read"
	new_object.save


	w = 0
	while w < 8
		File.delete("tempimg/" + prepend + "_" + w.to_s + ".jpg")
		if (w < 4)
			File.delete("tempimg/" + prepend + "_" + w.to_s + "_pair.jpg")
		end
		w += 1
	end
	File.delete("tempimg/" + prepend + "_final.jpg")

	imagefile = "http://s3.amazonaws.com/treasurypin/public/" + @filename


	returnString = "<a href=\"http://pinterest.com/pin/create/button/?url=" + CGI::escape(url) + "&media=" + CGI::escape(imagefile) + "\" class=\"pin-it-button\" count-layout=\"none\" target=\"_new\"><img border=\"0\" src=\"//assets.pinterest.com/images/PinExt.png\" title=\"Pin It\" /></a><BR><img src=\"" + imagefile + "\">";

	logger.info returnString

	render :text => returnString

  end
end
