local Jita = Apollo.GetAddon("Jita")
local ChatWindow = Jita:Extend("ChatWindow")

local Utils = Jita.Utils

--

function ChatWindow:CreateSuggestedMenu(wndTextBox)
	local wndMain = Apollo.LoadForm(Jita.XmlDoc, "SuggestedMenuControl", wndTextBox, self)

	self.SuggestedMenu =
	{
		["Main"] = wndMain,
		["SuggestedMenuContent"] = wndMain:FindChild("SuggestedMenuContent"),
		["Title"] = wndMain:FindChild("Title")
	}

	self.SuggestedMenu["Main"]:Show(false, true)

	--sizing maybe comeback and optimize! -- But you never did, eh?.
	local wndSuggestedMenuEntry = Apollo.LoadForm(Jita.XmlDoc, "SuggestedMenuEntryControl", nil, self)
	self.SuggestedMenuEntrySize = wndSuggestedMenuEntry:GetHeight()
	wndSuggestedMenuEntry:Destroy()
	wndSuggestedMenuEntry = nil

	local nLeft, nTop, nRight, nBottom = self.SuggestedMenu["Main"]:GetAnchorOffsets()
	self.SuggestedMenuDefaultMenuTop = nTop
end

function ChatWindow:ShowSuggestedMenu(text)
	if not self.SuggestedMenu then
		return
	end

	if not text then
		self:HideSuggestedMenu()

		return
	end

	text = Utils:LTrim(text)

	local fc = string.sub(text, 1, 1)

	if  fc ~= '/'
	and fc ~= '!'
	and fc ~= '&'
	and fc ~= '@'
	then
		self:HideSuggestedMenu()

		return
	end

	--

	local kMaxEntries      = 64
	local kMaxShownEntries = 8

	self.SuggestedMenu["SuggestedMenuContent"]:DestroyChildren()
	self.SuggestedMenuEntires = {}
	local tAlphabatized = {}

	-- Todo:
	-- this can be improved upon.
	if Utils:StringStarts(text, "/w ") or Utils:StringStarts(text, "/aw ") then
		local friendList = FriendshipLib.GetList()

		if friendList then
			for _, friend in pairs(friendList) do
				if friend and friend.bFriend then
					table.insert(tAlphabatized, { Text = "/w " .. friend.strCharacterName})
				end
			end
		end

		local accountFriends = FriendshipLib.GetAccountList()

		if accountFriends then
			for _, friend in pairs(accountFriends) do
				if friend and friend.strCharacterName then
					table.insert(tAlphabatized, { Text = "/aw " .. friend.strCharacterName})
				end
			end
		end
	else
		local commands = ChatSystemLib.GetCommands()

		for _, command in pairs(commands) do 
			if command ~= "" and command ~= nil then
				table.insert(tAlphabatized, { Text = "/" .. command })
			end
		end

		--

		table.insert(tAlphabatized, { Text = "!help"          })
		table.insert(tAlphabatized, { Text = "!commands"      })
		table.insert(tAlphabatized, { Text = "!macros"        })
		table.insert(tAlphabatized, { Text = "!clear"         })
		table.insert(tAlphabatized, { Text = "!config"        })
		table.insert(tAlphabatized, { Text = "!clone"         })
		table.insert(tAlphabatized, { Text = "!close"         })
		table.insert(tAlphabatized, { Text = "!quit"          })
		table.insert(tAlphabatized, { Text = "!opacity"       })
		table.insert(tAlphabatized, { Text = "!roster"        })
		table.insert(tAlphabatized, { Text = "!sidebar"       })
		table.insert(tAlphabatized, { Text = "!whois"         })
		table.insert(tAlphabatized, { Text = "!channels"      })
		table.insert(tAlphabatized, { Text = "!transcript"    })
		table.insert(tAlphabatized, { Text = "!notifications" })

		--

		table.insert(tAlphabatized, { Text = "&me"          })
		table.insert(tAlphabatized, { Text = "&faction"     })
		table.insert(tAlphabatized, { Text = "&race"        })
		table.insert(tAlphabatized, { Text = "&gender"      })
		table.insert(tAlphabatized, { Text = "&class"       })
		table.insert(tAlphabatized, { Text = "&path"        })
		table.insert(tAlphabatized, { Text = "&guild"       })
		table.insert(tAlphabatized, { Text = "&level"       })
		table.insert(tAlphabatized, { Text = "&ilevel"      })
		table.insert(tAlphabatized, { Text = "&items"       })
		table.insert(tAlphabatized, { Text = "&navpoint"    })
		table.insert(tAlphabatized, { Text = "&weapon"      })
		table.insert(tAlphabatized, { Text = "&shoulder"    })
		table.insert(tAlphabatized, { Text = "&head"        })
		table.insert(tAlphabatized, { Text = "&chest"       })
		table.insert(tAlphabatized, { Text = "&hands"       })
		table.insert(tAlphabatized, { Text = "&legs"        })
		table.insert(tAlphabatized, { Text = "&feet"        })
		table.insert(tAlphabatized, { Text = "&implant"     })
		table.insert(tAlphabatized, { Text = "&shields"     })
		table.insert(tAlphabatized, { Text = "&gadget"      })
		table.insert(tAlphabatized, { Text = "&costume"     })
		table.insert(tAlphabatized, { Text = "&location"    })
		table.insert(tAlphabatized, { Text = "&money"       })
		table.insert(tAlphabatized, { Text = "&omnibits"    })
		table.insert(tAlphabatized, { Text = "&pets"        })
		table.insert(tAlphabatized, { Text = "&target"      })
		table.insert(tAlphabatized, { Text = "&nearby"      })
		table.insert(tAlphabatized, { Text = "&party"       })
		table.insert(tAlphabatized, { Text = "&friendlist"  })
		table.insert(tAlphabatized, { Text = "&ignorelist"  })
		table.insert(tAlphabatized, { Text = "&neighborlist"})
		table.insert(tAlphabatized, { Text = "&channels"    })
		table.insert(tAlphabatized, { Text = "&circles"     })
		table.insert(tAlphabatized, { Text = "&pvet3"       })
		table.insert(tAlphabatized, { Text = "&pvpt3"       })
		table.insert(tAlphabatized, { Text = "&time"        })
		table.insert(tAlphabatized, { Text = "&fps"         })
		table.insert(tAlphabatized, { Text = "&lag"         })

		--

		local stream = Jita.Client:GetStream(self.SelectedStream)

		if stream then
			for _, member in ipairs(stream.Members) do
				table.insert(tAlphabatized, { Text = "@" .. member.Name})
			end
		end
	end

	--

	table.sort(tAlphabatized, function(a,b) return (a.Text < b.Text) end)

	local cp = 1

	for idx, tSuggestedInfo in pairs(tAlphabatized) do
		if cp < kMaxEntries then
			local strSuggestedSubString = string.sub(tSuggestedInfo.Text, 1 ,Apollo.StringLength(text))

			if Apollo.StringToLower(strSuggestedSubString) == Apollo.StringToLower(text) then
				self:CreateSuggestedMenuEntry(tSuggestedInfo)

				cp = cp + 1
			end
		end
	end

	if #self.SuggestedMenuEntires > 0 then
		self.SuggestedMenuSelectedEntryPosition = 1

		self.SuggestedMenuEntires[1]:FindChild("EntryName"):SetTextColor(ApolloColor.new("white"))

		local nLeft, nTop, nRight, nBottom = self.SuggestedMenu["Main"]:GetAnchorOffsets()
		self.SuggestedMenu["Main"]:SetAnchorOffsets(nLeft, self.SuggestedMenuDefaultMenuTop - (math.min(#self.SuggestedMenuEntires, kMaxShownEntries) * self.SuggestedMenuEntrySize), nRight, nBottom)

		self.SuggestedMenu["SuggestedMenuContent"]:ArrangeChildrenVert()
		self.SuggestedMenu["SuggestedMenuContent"]:SetVScrollPos(0) 

		self.SuggestedMenu["Main"]:Invoke()

		return
	end
	
	self:HideSuggestedMenu()
end

function ChatWindow:CreateSuggestedMenuEntry(tInfo)
	if not self.SuggestedMenuEntires or not tInfo or not tInfo.Text then 
		return
	end
	
	local text = tInfo.Text

	text = string.gsub(text, "/w ", "")
	text = string.gsub(text, "/aw ", "")

	local wndEntryForm = Apollo.LoadForm(Jita.XmlDoc, "SuggestedMenuEntryControl", self.SuggestedMenu["SuggestedMenuContent"], self)
	local wndMenuEntry = wndEntryForm:FindChild("SuggestedMenuEntry")
	wndMenuEntry:FindChild("EntryName"):SetText(text)
	wndMenuEntry:SetData(tInfo)
	table.insert(self.SuggestedMenuEntires, wndMenuEntry)
end

function ChatWindow:SelectSuggestedMenuEntry(entry)
	if not entry then
		return
	end

	local data = entry:GetData()

	if not data then
		return
	end

	self.ChatInputEditBox:SetText(data.Text)
	self.ChatInputEditBox:SetFocus()
	self.ChatInputEditBox:SetSel(data.Text:len(), -1)

	self:HideSuggestedMenu()
end

function ChatWindow:OnSuggestedMenuEntryClick(wndHandler, wndControl)
	self:SelectSuggestedMenuEntry(wndControl)
end

function ChatWindow:HideSuggestedMenu()
	if not self.SuggestedMenu then
		return
	end

	self.SuggestedMenu["Main"]:Show(false)
	self.SuggestedMenu["SuggestedMenuContent"]:DestroyChildren()
	self.SuggestedMenuEntires = {}
end

function ChatWindow:IsSuggestedMenuShown()
	return self.SuggestedMenu and self.SuggestedMenu["Main"] and self.SuggestedMenu["Main"]:IsShown()
end
