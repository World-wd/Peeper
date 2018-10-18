class Head extends Class
	constructor: ->
		@menu = new Menu()
		@follows = []

	handleSelectUserClick: ->
		if "Merger:ZeroMe" not in Page.site_info.settings.permissions
			Page.cmd "wrapperPermissionAdd", "Merger:ZeroMe", =>
				Page.updateSiteInfo =>
					Page.content.update()
		else
			Page.cmd "certSelect", {"accepted_domains": ["zeroid.bit"; "kxoid.bit"], "accept_any": true}
		return false

	handleFollowMenuItemClick: (type, item) =>
		selected = not @follows[type]
		@follows[type] = selected
		item[2] = selected
		@saveFollows()
		Page.projector.scheduleRender()
		return true

	handleMenuClick: =>
		if not Page.site_info?.cert_user_id
			return @handleSelectUserClick()
		Page.cmd "feedListFollow", [], (@follows) =>
			@menu.items = []

			@menu.items.push ["Follow username mentions", ( (item) =>
				return @handleFollowMenuItemClick("Mentions", item)
			), @follows["Mentions"]]

			@menu.items.push ["Follow comments on your posts", ( (item) =>
				return @handleFollowMenuItemClick("Comments on your posts", item)
			), @follows["Comments on your posts"]]

			@menu.items.push ["Follow new followers", ( (item) =>
				return @handleFollowMenuItemClick("New followers", item)
			), @follows["New followers"]]

			@menu.items.push ["Hide \"Hello ZeroMe!\" messages", ( (item) =>
				Page.local_storage.settings.hide_hello_zerome = not Page.local_storage.settings.hide_hello_zerome
				item[2] = Page.local_storage.settings.hide_hello_zerome
				Page.projector.scheduleRender()
				Page.saveLocalStorage()
				Page.content.need_update = true
				return false
			), Page.local_storage.settings.hide_hello_zerome]

			if (key for key of Page.user_hubs).length > 1
				@menu.items.push ["---"]
				for key, val of Page.user_hubs
					((key) =>
						@menu.items.push ["Use hub #{key}", ( (item) =>
							Page.local_storage.settings.hub = key
							Page.saveLocalStorage()
							Page.checkUser()
						), Page.user.row.site == key]
					)(key)
					
			@menu.toggle()
			Page.projector.scheduleRender()
		return false

	saveFollows: =>
		out = {}
		if @follows["Mentions"]
			out["Mentions"] = ["
				SELECT
				 'mention' AS type,
				 comment.date_added AS date_added,
				 'a comment' AS title,
				 '@' || user_name || ': ' || comment.body AS body,
				 '?Post/' || json.site || '/' || REPLACE(post_uri, '_', '/') AS url
				FROM comment
				LEFT JOIN json USING (json_id)
				WHERE
				 comment.body LIKE '%@#{Page.user.row.user_name}%'

				UNION

				SELECT
				 'mention' AS type,
				 post.date_added AS date_added,
				 'In ' || json.user_name || \"'s post\" AS title,
				 post.body AS body,
				 '?Post/' || json.site || '/' || REPLACE(json.directory, 'data/users/', '') || '/' || post_id AS url
				FROM post
				LEFT JOIN json USING (json_id)
				WHERE
				 post.body LIKE '%@#{Page.user.row.user_name}%'
			", [""]]

		if @follows["Comments on your posts"]
			out["Comments on your posts"] = ["
				SELECT
				 'comment' AS type,
				 comment.date_added AS date_added,
				 'Your post' AS title,
				 '@' || json.user_name || ': ' || comment.body AS body,
				 '?Post/' || site || '/' || REPLACE(post_uri, '_', '/') AS url
				FROM comment
				LEFT JOIN json USING (json_id)
				WHERE
				post_uri LIKE '#{Page.user.auth_address}%'
			", [""]]

		if @follows["New followers"]
			out["New followers"] = ["
				SELECT
				 'follow' AS type,
				 follow.date_added AS date_added,
				 json.user_name || ' started following you' AS title,
				 '' AS body,
				 '?Profile/' || json.hub || REPLACE(json.directory, 'data/users', '') AS url
 				FROM follow
 				LEFT JOIN json USING(json_id)
 				WHERE
 				auth_address = '#{Page.user.auth_address}'
 				GROUP BY json.directory
 			", [""]]

		Page.cmd "feedFollow", [out]



	render: =>
		h("div.head.center", [
			if Page.getSetting("logo_left")
				h("div.logo", [
					h("svg", {width: "40px", height: "40px", viewBox: "0 0 437 438", version: "1.1", xmlns: "http://www.w3.org/2000/svg"}
						h("path", {fill: "transparent", opacity: "1.00", d: " M 216.5 0.0 L 220.5 0.0 C 229.2 0.8 237.9 0.6 246.6 1.7 C 256.1 2.8 265.4 5.0 274.6 7.4 C 288.2 10.8 301.3 15.7 313.8 22.1 C 357.8 43.1 394.1 79.7 415.2 123.7 C 426.3 146.8 433.5 171.8 435.9 197.2 C 436.4 204.0 436.5 210.7 437.0 217.4 L 437.0 220.6 C 436.5 227.0 436.4 233.4 435.9 239.9 C 433.5 267.6 425.3 294.8 412.6 319.6 C 392.6 358.3 360.9 390.9 322.5 411.5 C 300.9 423.6 277.0 431.2 252.7 435.4 C 242.1 437.4 231.2 437.2 220.5 438.0 L 216.5 438.0 C 210.0 437.5 203.4 437.3 196.9 437.0 C 187.8 436.2 178.7 434.8 169.9 432.3 C 170.1 428.9 170.2 425.4 170.3 422.0 C 170.2 383.7 170.2 345.3 170.2 307.0 C 170.2 302.3 170.0 297.7 170.3 293.0 C 174.8 294.0 178.7 296.4 182.8 298.2 C 191.9 302.1 201.2 305.6 211.0 307.1 C 226.2 309.9 242.1 309.1 257.0 305.1 C 272.7 300.5 287.3 292.4 299.5 281.6 C 313.9 268.8 326.3 253.3 333.3 235.2 C 339.8 219.7 342.2 202.7 341.7 185.9 C 341.5 164.9 335.1 143.9 323.7 126.2 C 312.4 109.2 297.1 94.7 279.0 85.0 C 266.2 78.5 252.4 73.8 238.0 72.7 C 229.6 71.7 221.1 71.4 212.7 72.4 C 198.2 73.3 184.1 77.7 171.2 84.1 C 145.4 96.7 124.6 119.0 113.4 145.4 C 110.3 152.7 109.0 160.6 107.5 168.3 C 105.4 179.8 105.2 191.4 104.8 203.0 C 104.5 209.7 104.7 216.3 104.7 223.0 C 104.7 274.7 104.7 326.3 104.7 378.0 C 104.6 387.2 104.8 396.3 104.4 405.5 C 99.8 402.9 95.4 400.0 91.2 396.9 C 56.2 371.9 29.1 336.3 14.0 296.1 C 7.6 278.3 3.3 259.8 1.3 241.0 C 0.7 234.2 0.7 227.4 0.0 220.6 L 0.0 217.4 C 1.0 208.0 0.7 198.4 2.2 189.0 C 5.5 168.5 10.7 148.3 19.4 129.5 C 23.3 119.8 28.8 111.0 34.1 102.1 C 53.9 70.9 81.6 44.7 114.0 27.0 C 136.5 14.5 161.3 6.3 186.7 2.5 C 196.5 0.5 206.6 0.8 216.5 0.0 Z"}),
						h("path", {fill: "#fcc63a", opacity: "1.00", d: " M 212.7 72.4 C 221.1 71.4 229.6 71.7 238.0 72.7 C 252.4 73.8 266.2 78.5 279.0 85.0 C 297.1 94.7 312.4 109.2 323.7 126.2 C 335.1 143.9 341.5 164.9 341.7 185.9 C 342.2 202.7 339.8 219.7 333.3 235.2 C 326.3 253.3 313.9 268.8 299.5 281.6 C 287.3 292.4 272.7 300.5 257.0 305.1 C 242.1 309.1 226.2 309.9 211.0 307.1 C 201.2 305.6 191.9 302.1 182.8 298.2 C 178.7 296.4 174.8 294.0 170.3 293.0 C 170.0 297.7 170.2 302.3 170.2 307.0 C 170.2 345.3 170.2 383.7 170.3 422.0 C 170.2 425.4 170.1 428.9 169.9 432.3 C 146.7 427.3 124.4 418.3 104.4 405.5 C 104.8 396.3 104.6 387.2 104.7 378.0 C 104.7 326.3 104.7 274.7 104.7 223.0 C 104.7 216.3 104.5 209.7 104.8 203.0 C 105.2 191.4 105.4 179.8 107.5 168.3 C 109.0 160.6 110.3 152.7 113.4 145.4 C 124.6 119.0 145.4 96.7 171.2 84.1 C 184.1 77.7 198.2 73.3 212.7 72.4 M 217.4 136.2 C 212.2 136.8 207.0 138.0 202.2 140.2 C 195.4 143.3 189.7 148.2 184.6 153.6 C 179.2 159.6 175.0 166.7 172.5 174.4 C 170.7 179.7 170.6 185.4 170.6 191.0 C 170.7 196.4 171.0 202.0 172.9 207.2 C 175.6 214.5 179.0 221.8 184.6 227.4 C 191.9 235.5 201.6 241.1 212.2 243.6 C 220.7 245.0 229.5 244.7 237.9 242.8 C 251.5 239.5 262.6 229.5 269.5 217.6 C 277.7 202.6 278.9 183.8 271.9 168.1 C 268.1 159.0 261.2 151.5 253.6 145.4 C 243.3 137.9 230.0 134.2 217.4 136.2 Z"}),
						h("path", {fill: "transparent", opacity: "1.00", d: " M 217.4 136.2 C 230.0 134.2 243.3 137.9 253.6 145.4 C 261.2 151.5 268.1 159.0 271.9 168.1 C 278.9 183.8 277.7 202.6 269.5 217.6 C 262.6 229.5 251.5 239.5 237.9 242.8 C 229.5 244.7 220.7 245.0 212.2 243.6 C 201.6 241.1 191.9 235.5 184.6 227.4 C 179.0 221.8 175.6 214.5 172.9 207.2 C 171.0 202.0 170.7 196.4 170.6 191.0 C 170.6 185.4 170.7 179.7 172.5 174.4 C 175.0 166.7 179.2 159.6 184.6 153.6 C 189.7 148.2 195.4 143.3 202.2 140.2 C 207.0 138.0 212.2 136.8 217.4 136.2 M 215.4 155.6 C 204.3 158.4 194.5 166.5 190.1 177.1 C 185.7 187.0 186.3 198.9 191.6 208.4 C 195.9 217.2 204.3 223.4 213.4 226.5 C 218.0 228.1 223.0 227.9 227.8 227.6 C 236.0 227.2 243.6 223.1 249.6 217.6 C 255.2 212.2 258.8 204.9 260.3 197.4 C 262.0 187.2 259.2 176.4 252.6 168.4 C 244.0 157.4 228.9 152.2 215.4 155.6 Z"}),
						h("path", {fill: "#fcc63a", opacity: "1.00", d: " M 215.4 155.6 C 228.9 152.2 244.0 157.4 252.6 168.4 C 259.2 176.4 262.0 187.2 260.3 197.4 C 258.8 204.9 255.2 212.2 249.6 217.6 C 243.6 223.1 236.0 227.2 227.8 227.6 C 223.0 227.9 218.0 228.1 213.4 226.5 C 204.3 223.4 195.9 217.2 191.6 208.4 C 186.3 198.9 185.7 187.0 190.1 177.1 C 194.5 166.5 204.3 158.4 215.4 155.6 Z"})
					)
				])

			h("ul", [
				for el in [["Home",'Home',"home"],["Users",'Users',"users"],["Settings",'Settings',"gear"],["",'Donate',"heart"],["",'Badges',"certificate"]]
					h("li",h("a",{href:"?#{el[1]}", onclick: Page.handleLinkClick},[h("i.fa.fa-margin.fa-#{el[2]}"),el[0]]))
			]),
			
			if not Page.getSetting("logo_left")
				h("div.logo", [
					h("svg", {width: "40px", height: "40px", viewBox: "0 0 437 438", version: "1.1", xmlns: "http://www.w3.org/2000/svg"}
						h("path", {fill: "transparent", opacity: "1.00", d: " M 216.5 0.0 L 220.5 0.0 C 229.2 0.8 237.9 0.6 246.6 1.7 C 256.1 2.8 265.4 5.0 274.6 7.4 C 288.2 10.8 301.3 15.7 313.8 22.1 C 357.8 43.1 394.1 79.7 415.2 123.7 C 426.3 146.8 433.5 171.8 435.9 197.2 C 436.4 204.0 436.5 210.7 437.0 217.4 L 437.0 220.6 C 436.5 227.0 436.4 233.4 435.9 239.9 C 433.5 267.6 425.3 294.8 412.6 319.6 C 392.6 358.3 360.9 390.9 322.5 411.5 C 300.9 423.6 277.0 431.2 252.7 435.4 C 242.1 437.4 231.2 437.2 220.5 438.0 L 216.5 438.0 C 210.0 437.5 203.4 437.3 196.9 437.0 C 187.8 436.2 178.7 434.8 169.9 432.3 C 170.1 428.9 170.2 425.4 170.3 422.0 C 170.2 383.7 170.2 345.3 170.2 307.0 C 170.2 302.3 170.0 297.7 170.3 293.0 C 174.8 294.0 178.7 296.4 182.8 298.2 C 191.9 302.1 201.2 305.6 211.0 307.1 C 226.2 309.9 242.1 309.1 257.0 305.1 C 272.7 300.5 287.3 292.4 299.5 281.6 C 313.9 268.8 326.3 253.3 333.3 235.2 C 339.8 219.7 342.2 202.7 341.7 185.9 C 341.5 164.9 335.1 143.9 323.7 126.2 C 312.4 109.2 297.1 94.7 279.0 85.0 C 266.2 78.5 252.4 73.8 238.0 72.7 C 229.6 71.7 221.1 71.4 212.7 72.4 C 198.2 73.3 184.1 77.7 171.2 84.1 C 145.4 96.7 124.6 119.0 113.4 145.4 C 110.3 152.7 109.0 160.6 107.5 168.3 C 105.4 179.8 105.2 191.4 104.8 203.0 C 104.5 209.7 104.7 216.3 104.7 223.0 C 104.7 274.7 104.7 326.3 104.7 378.0 C 104.6 387.2 104.8 396.3 104.4 405.5 C 99.8 402.9 95.4 400.0 91.2 396.9 C 56.2 371.9 29.1 336.3 14.0 296.1 C 7.6 278.3 3.3 259.8 1.3 241.0 C 0.7 234.2 0.7 227.4 0.0 220.6 L 0.0 217.4 C 1.0 208.0 0.7 198.4 2.2 189.0 C 5.5 168.5 10.7 148.3 19.4 129.5 C 23.3 119.8 28.8 111.0 34.1 102.1 C 53.9 70.9 81.6 44.7 114.0 27.0 C 136.5 14.5 161.3 6.3 186.7 2.5 C 196.5 0.5 206.6 0.8 216.5 0.0 Z"}),
						h("path", {fill: "#fcc63a", opacity: "1.00", d: " M 212.7 72.4 C 221.1 71.4 229.6 71.7 238.0 72.7 C 252.4 73.8 266.2 78.5 279.0 85.0 C 297.1 94.7 312.4 109.2 323.7 126.2 C 335.1 143.9 341.5 164.9 341.7 185.9 C 342.2 202.7 339.8 219.7 333.3 235.2 C 326.3 253.3 313.9 268.8 299.5 281.6 C 287.3 292.4 272.7 300.5 257.0 305.1 C 242.1 309.1 226.2 309.9 211.0 307.1 C 201.2 305.6 191.9 302.1 182.8 298.2 C 178.7 296.4 174.8 294.0 170.3 293.0 C 170.0 297.7 170.2 302.3 170.2 307.0 C 170.2 345.3 170.2 383.7 170.3 422.0 C 170.2 425.4 170.1 428.9 169.9 432.3 C 146.7 427.3 124.4 418.3 104.4 405.5 C 104.8 396.3 104.6 387.2 104.7 378.0 C 104.7 326.3 104.7 274.7 104.7 223.0 C 104.7 216.3 104.5 209.7 104.8 203.0 C 105.2 191.4 105.4 179.8 107.5 168.3 C 109.0 160.6 110.3 152.7 113.4 145.4 C 124.6 119.0 145.4 96.7 171.2 84.1 C 184.1 77.7 198.2 73.3 212.7 72.4 M 217.4 136.2 C 212.2 136.8 207.0 138.0 202.2 140.2 C 195.4 143.3 189.7 148.2 184.6 153.6 C 179.2 159.6 175.0 166.7 172.5 174.4 C 170.7 179.7 170.6 185.4 170.6 191.0 C 170.7 196.4 171.0 202.0 172.9 207.2 C 175.6 214.5 179.0 221.8 184.6 227.4 C 191.9 235.5 201.6 241.1 212.2 243.6 C 220.7 245.0 229.5 244.7 237.9 242.8 C 251.5 239.5 262.6 229.5 269.5 217.6 C 277.7 202.6 278.9 183.8 271.9 168.1 C 268.1 159.0 261.2 151.5 253.6 145.4 C 243.3 137.9 230.0 134.2 217.4 136.2 Z"}),
						h("path", {fill: "transparent", opacity: "1.00", d: " M 217.4 136.2 C 230.0 134.2 243.3 137.9 253.6 145.4 C 261.2 151.5 268.1 159.0 271.9 168.1 C 278.9 183.8 277.7 202.6 269.5 217.6 C 262.6 229.5 251.5 239.5 237.9 242.8 C 229.5 244.7 220.7 245.0 212.2 243.6 C 201.6 241.1 191.9 235.5 184.6 227.4 C 179.0 221.8 175.6 214.5 172.9 207.2 C 171.0 202.0 170.7 196.4 170.6 191.0 C 170.6 185.4 170.7 179.7 172.5 174.4 C 175.0 166.7 179.2 159.6 184.6 153.6 C 189.7 148.2 195.4 143.3 202.2 140.2 C 207.0 138.0 212.2 136.8 217.4 136.2 M 215.4 155.6 C 204.3 158.4 194.5 166.5 190.1 177.1 C 185.7 187.0 186.3 198.9 191.6 208.4 C 195.9 217.2 204.3 223.4 213.4 226.5 C 218.0 228.1 223.0 227.9 227.8 227.6 C 236.0 227.2 243.6 223.1 249.6 217.6 C 255.2 212.2 258.8 204.9 260.3 197.4 C 262.0 187.2 259.2 176.4 252.6 168.4 C 244.0 157.4 228.9 152.2 215.4 155.6 Z"}),
						h("path", {fill: "#fcc63a", opacity: "1.00", d: " M 215.4 155.6 C 228.9 152.2 244.0 157.4 252.6 168.4 C 259.2 176.4 262.0 187.2 260.3 197.4 C 258.8 204.9 255.2 212.2 249.6 217.6 C 243.6 223.1 236.0 227.2 227.8 227.6 C 223.0 227.9 218.0 228.1 213.4 226.5 C 204.3 223.4 195.9 217.2 191.6 208.4 C 186.3 198.9 185.7 187.0 190.1 177.1 C 194.5 166.5 204.3 158.4 215.4 155.6 Z"})
					)
				])
				
			if Page.user?.hub
				# Registered user
				h("div.right.authenticated", [
					h("div.user",
						h("div.box3.sb13", {onclick: "fullscreen"}, 'New post'),
						h("img.avatar", {src: Page.user.getAvatarLink(), alt: Page.user.row.user_name, title: Page.user.row.user_name}),
						h("a.name.link", {href: Page.user.getLink(), onclick: Page.handleLinkClick}, Page.user.row.user_name),
						h("a.address", {href: "#Select+user", onclick: @handleSelectUserClick}, Page.site_info.cert_user_id)
					),
					h("a.settings", {href: "#Settings", onclick: Page.returnFalse, onmousedown: @handleMenuClick}, "\u22EE")
					@menu.render()
				])
			else if not Page.user?.hub and Page.site_info?.cert_user_id
				# Cert selected, but not registered
				h("div.right.selected", [
					h("div.user",
						h("a.name.link", {href: "?Create+profile", onclick: Page.handleLinkClick}, "Create profile"),
						h("a.address", {href: "#Select+user", onclick: @handleSelectUserClick}, Page.site_info.cert_user_id)
					),
					@menu.render()
					h("a.settings", {href: "#Settings", onclick: Page.returnFalse, onmousedown: @handleMenuClick}, "\u22EE")
				])
			else if not Page.user?.hub and Page.site_info
				# No cert selected
				h("div.right.unknown", [
					h("div.user",
						h("a.name.link", {href: "#Select+user", onclick: @handleSelectUserClick}, "Visitor"),
						h("a.address", {href: "#Select+user", onclick: @handleSelectUserClick}, "Select your account")
					),
					@menu.render()
					h("a.settings", {href: "#Settings", onclick: Page.returnFalse, onmousedown: @handleMenuClick}, "\u22EE")
				])
			else
				h("div.right.unknown")
		])

window.Head = Head
