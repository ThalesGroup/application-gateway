local defaultPlugin = {}
local log = ngx.log
local DEBUG = ngx.DEBUG
local ERROR = ngx.ERR
local WARN = ngx.WARN
local basicAuthScheme = "HTTP BASIC"
local defaultPluginName = "defaultPlugin"
local formAuthScheme = "FORM AUTHENTICATION"
local cookie = require "resty.cookie"


local HeaderAttributeTypes = {
    Header = "header",
    Cookie = "cookie",
    Params = "params",
    Form = "form"
}


------------------------------------------------------------------------------------------------------------------------
-- INTERFACE METHODS
------------------------------------------------------------------------------------------------------------------------



--- This method is called after the user has completed the STA authentication successfully.
-- The method can be used to capture and modify login request before it is passed to the protected end application.
-- The helper methods to modify headers, cookies, query parameters and form data are already included in this file.
-- @param attributeValues It is the collection of attributes configured in STA for the accessed application.For each attribute it has HeaderName,HeaderType,HeaderValue and CustomHeaderValue.
-- @param idToken It is the id token JWT received from STA after authentication.
-- @param authScheme It is the application's authentication scheme.
-- @param LoginUrl It is the application's login url as configured in STA.
-- @param authSession It is the current authentication context.It contains data related to current session.
function defaultPlugin.postLoginRequestHandler(attributeValues,idToken,authScheme,LoginUrl,authSession)
    
    defaultPlugin.processAttributes(attributeValues,idToken,authScheme,LoginUrl,authSession) 

end
 
--- This method is called just before STA logout is initiated.
-- The method can be used execute any logic before STA logout flow is initiated.
-- @param attributeValues It is the collection of attributes configured in STA for the accessed application.For each attribute it has HeaderName,HeaderType,HeaderValue and CustomHeaderValue.
-- @param authScheme It is the application's authentication scheme.
-- @param LogoutUrl It is the application's logout url as configured in STA.
function defaultPlugin.preLogoutRequestHandler(attributeValues,authScheme,LogoutUrl)
    -- add Logic
end

--- This method is called before the response is returned to the HTTP clients (browsers)
-- The method can be used to modify the response before it is sent to the HTTP clients
-- @param authScheme It is the application's authentication scheme.
-- @param LoginUrl It is the application's login url as configured in STA.
-- @param LogoutUrl It is the application's logout url as configured in STA.
function defaultPlugin.PreResponseHandler(authScheme,LoginUrl,LogoutUrl)
    -- add Logic
end

--- This method provides the friendly name of the application for which the plugin needs to be executed
-- @return application friendly name
function defaultPlugin.getAppFriendlyName()
    return "defaultPlugin"
end
 
--- This method provides the location of the HTML page containing plugin javascript code
-- Application Gateway uses it to execute any custom javascript in case of form based authentication
-- @return path to plugin's HTML page. It would be a path within customPlugins folder.
function defaultPlugin.getFormHtml()
    return "/standardPlugins/defaultPluginTemplate.html"
end

--- This method indicates the Plugin Version which is deployed in the Safenet Application Gateway Setup.
-- @return the version number of the Plugin Module, default version is v1.
function defaultPlugin.getPluginVersion()
    return "v1"
end

------------------------------------------------------------------------------------------------------------------------
-- HELPER METHODS
------------------------------------------------------------------------------------------------------------------------

--- This method is called in order to process the application attributes which are configured on STA console for accessed application.
-- The attributes can be Header, Cookie, Querey Parameter or Form Based.
-- @param headerAttributes It is the collection of attributes configured in STA for the accessed application.For each attribute it has HeaderName,HeaderType,HeaderValue and CustomHeaderValue.
-- @param idToken It is the id token JWT received from STA after authentication.
-- @param authScheme It is the application's authentication scheme.
-- @param LoginUrl It is the application's login url as configured in STA.
-- @param authSession It is the current authentication context.It contains data related to current session.
defaultPlugin.processAttributes =function(headerAttributes,idToken,authScheme,LoginUrl,authSession)

    defaultPlugin.setHeaderAttributes(headerAttributes,idToken,authScheme)
    defaultPlugin.setCookieAttributes(headerAttributes,idToken,authScheme)
    defaultPlugin.setQueryParamAttributes(headerAttributes,idToken,authScheme)

	if ngx.var.request_method == "POST" and ngx.var.request_uri == LoginUrl then
	   defaultPlugin.setFormAttributes(headerAttributes,idToken,authScheme,authSession)
  end
end

--- This method is used to set request headers before passing it to protected end application.
-- This method gets Header attributes as request headers and forward it with authentciation request.
-- @param headerAttributes It is the collection of attributes configured in STA for the accessed application.For each attribute it has HeaderName,HeaderType,HeaderValue and CustomHeaderValue.
-- @param idToken It is the id token JWT received from STA after authentication.
-- @param authScheme It is the application's authentication scheme.
defaultPlugin.setHeaderAttributes = function(headerAttributes,idToken,authScheme)
if headerAttributes ~= nil and next(headerAttributes) ~= nil then
    for key, value in next, headerAttributes do
        if  string.lower(value.HeaderType) == HeaderAttributeTypes.Header then
			local attributeValue = defaultPlugin.getHeaderAttributeValue(value, idToken)
			ngx.req.set_header(value.HeaderName, attributeValue)
        end
    end
end
ngx.req.set_header("X-USER", idToken.sub)

end

--- This method is used to set cookies before passing the request to protected end application.
-- This method sets Cookie attributes as CookieValues and forward it as cookies with authentciation request.
-- @param headerAttributes It is the collection of attributes configured in STA for the accessed application.For each attribute it has HeaderName,HeaderType,HeaderValue and CustomHeaderValue.
-- @param idToken It is the id token JWT received from STA after authentication.
-- @param authScheme It is the application's authentication scheme.
defaultPlugin.setCookieAttributes = function(headerAttributes,idToken,authScheme)
-- local concatCookieValues = ngx.req.get_headers()['Cookie']
if headerAttributes ~= nil and next(headerAttributes) ~= nil then
    for key, value in next, headerAttributes do
	local cookieValue = defaultPlugin.getHeaderAttributeValue(value, idToken)
        if  string.lower(value.HeaderType) == HeaderAttributeTypes.Cookie then
            -- concatCookieValues = concatCookieValues .. "" .. cookieValue
			cookieValue1 = defaultPlugin.setCookieValue(value.HeaderName, cookieValue)
            local CustomValue, params = string.match(cookieValue, "([^,]+),(.+)")
             if CustomValue == nil and params == nil then
                CustomValue = cookieValue
             end
            defaultPlugin.setCookieValue(name, CustomValue, params)	
        end
    end
--    ngx.req.set_header("Cookie", concatCookieValues)
end
end

defaultPlugin.setCookieValue = function(name, value, CookieParameters)
    local Cookie = {}
    local Cookies, err = cookie:new()
    Cookie.key = name
    Cookie.value = value

    if CookieParameters ~= nil and CookieParameters ~= "" then
        local CookieTexts = defaultPlugin.split_string(CookieParameters)
        if CookieTexts ~= nil and CookieTexts ~= "" then
            for CookieKey, CookieValue in pairs(CookieTexts) do
                if  CookieKey:lower() == "path" or  CookieKey:lower() == "domain" or CookieKey:lower() == "secure"  or CookieKey:lower() == "expires"  or CookieKey:lower() == "max_age" or CookieKey:lower() == "samesite" or CookieKey:lower() == "extension" or CookieKey:lower() == "secure" or CookieKey:lower() == "httponly" then
                    Cookie[CookieKey:lower()]= CookieValue
                end
            end
        end

    end
        Cookies:set(Cookie)
    if not Cookies then
        ngx.log(ngx.ERR, "Cookies could not be set " .. err)
        return
    end
end


defaultPlugin.split_string = function (str)
    local result = {}
    for token in string.gmatch(str, "[^,]+") do
      local key, value = token:match("^%s*(.-)%s*:%s*(.-)%s*$")
      if key and value then
        result[key] = value
      end
    end
    return result
end

--- This method is used to set query parameters before passing the request to protected end application.
-- This method sets Params attributes as query string and forward it with authentciation request.
-- @param headerAttributes It is the collection of attributes configured in STA for the accessed application.For each attribute it has HeaderName,HeaderType,HeaderValue and CustomHeaderValue.
-- @param idToken It is the id token JWT received from STA after authentication.
-- @param authScheme It is the application's authentication scheme.
defaultPlugin.setQueryParamAttributes = function(headerAttributes,idToken,authScheme)
local concatParamTable = {}
if headerAttributes ~= nil and next(headerAttributes) ~= nil then
    for key, value in next, headerAttributes do
        if  string.lower(value.HeaderType) == HeaderAttributeTypes.Params then
            concatParamTable[value.HeaderName] = defaultPlugin.getHeaderAttributeValue(value,idToken)
        end
    end
    ngx.req.set_uri_args(concatParamTable)
end
end

--- This method is used to set form body before passing the request to protected end application in case of form based authentication scheme.
-- This method sets Form attributes as form body and forward it with authentciation request.
-- @param headerAttributes It is the collection of attributes configured in STA for the accessed application.For each attribute it has HeaderName,HeaderType,HeaderValue and CustomHeaderValue.
-- @param idToken It is the id token JWT received from STA after authentication.
-- @param authScheme It is the application's authentication scheme.
-- @param authSession It is the current authentication context.It contains data related to current session.
defaultPlugin.setFormAttributes = function(headerAttributes,idToken,authScheme,authSession)
    ngx.req.read_body()
    local oldbody = ngx.req.get_body_data()
    local params = ngx.req.get_post_args()
    local newFormFields = ""
    if headerAttributes ~= nil and next(headerAttributes) ~= nil then
        for key, value in next, headerAttributes do
	local formvalue = defaultPlugin.getHeaderAttributeValue(value, idToken)
	     if string.lower(value.HeaderType) == HeaderAttributeTypes.Form then
             --if fieldname is password then replace value with password in session
		if formvalue == '$password' then
		formvalue = authSession.password
		end
		newFormFields = newFormFields .. "&" .. value.HeaderName .. "=" .. formvalue
        end
        end
    end
    local newbody = oldbody .. newFormFields
    ngx.req.set_body_data(newbody)
end

--- This method is used to retrieve value for an attribute as per mapping done in STA App Gateway application configuration.
-- @return the values for each attribute which is set on STA console for the accessed application.
-- @param headerAttributes It is the attribute for which value is required as per configuration in STA for the accessed application. The attribute has HeaderName, HeaderType, HeaderValue and CustomHeaderValue.
-- @param idToken It is the id token JWT received from STA after authentication.
defaultPlugin.getHeaderAttributeValue = function(headerAttribute, idToken)
    local name = headerAttribute.HeaderName
    local value = ""
    local returnValue = ""
    if string.lower(headerAttribute.HeaderValue) == "custom value" then
        value = headerAttribute.CustomHeaderValue
    else
        local headerAttributeValue = defaultPlugin.fetchClaimValueBasedOnHeaderAttribute(idToken, headerAttribute.HeaderValue)
        if headerAttributeValue ~= "" then
            value = headerAttributeValue
        end
    end

    if value ~= "" then
        if string.lower(headerAttribute.HeaderType) == HeaderAttributeTypes.Header then
            returnValue = value
        elseif  string.lower(headerAttribute.HeaderType) == HeaderAttributeTypes.Cookie then
            returnValue = value -- name .." = " .. value .. ";"
        elseif  string.lower(headerAttribute.HeaderType) == HeaderAttributeTypes.Params then
			returnValue = value
		elseif string.lower(headerAttribute.HeaderType) == HeaderAttributeTypes.Form then
			returnValue = value
        end
    else
        ngx.log(ngx.ERR, "Header Attribute Value is empty for the following Header: " .. name)
    end
    return returnValue
end

--- This method retrieves value for an attribute from id token on the basis of mapping done in STA App Gateway application configuration.
-- @return the value for attributes names which is set on STA console for the accessed application.
-- @param headerAttribute It is the name of the attribute for which value is required.
-- @param idToken It is the id token JWT received from STA after authentication.
defaultPlugin.fetchClaimValueBasedOnHeaderAttribute = function(idToken, headerAttribute)
    local headerAttributeValue = ""
   ngx.log(ngx.DEBUG, "header attribute :: " .. headerAttribute)

    if headerAttribute ~= nil and headerAttribute ~= "" then
        if string.lower(headerAttribute) == string.lower("SAS User ID") then
            headerAttributeValue = idToken.preferred_username and idToken.preferred_username or ""
        elseif string.lower(headerAttribute) == string.lower("Email Address") then
            headerAttributeValue = idToken.EmailAddress and idToken.EmailAddress or ""
        elseif string.lower(headerAttribute) == string.lower("Name") then
            headerAttributeValue = idToken.name and idToken.name or ""
        elseif string.lower(headerAttribute) == string.lower("First Name") then
            headerAttributeValue = idToken.given_name and idToken.given_name or ""
        elseif string.lower(headerAttribute) == string.lower("Last Name") then
            headerAttributeValue = idToken.family_name and idToken.family_name or ""
        elseif string.lower(headerAttribute) == string.lower("Groups") then
            headerAttributeValue = idToken.Groups and idToken.Groups or ""
        elseif string.lower(headerAttribute) == string.lower("User Object GUID") then
            headerAttributeValue = idToken.UserObjectGUID and idToken.UserObjectGUID or ""
        elseif string.lower(headerAttribute) == string.lower("Alias #1") then
            headerAttributeValue = idToken.Alias1 and idToken.Alias1 or ""
        elseif string.lower(headerAttribute) == string.lower("Alias #2") then
            headerAttributeValue = idToken.Alias1 and idToken.Alias2 or ""
        elseif string.lower(headerAttribute) == string.lower("Alias #3") then
            headerAttributeValue = idToken.Alias1 and idToken.Alias3 or ""
        elseif string.lower(headerAttribute) == string.lower("Alias #4") then
            headerAttributeValue = idToken.Alias1 and idToken.Alias4 or ""
        elseif string.lower(headerAttribute) == string.lower("Custom #1") then
            headerAttributeValue = idToken.Custom1 and idToken.Custom1 or ""
        elseif string.lower(headerAttribute) == string.lower("Custom #2") then
            headerAttributeValue = idToken.Custom1 and idToken.Custom2 or ""
        elseif string.lower(headerAttribute) == string.lower("Custom #3") then
            headerAttributeValue = idToken.Custom1 and idToken.Custom3 or ""
        end
    end

    return headerAttributeValue
end

return defaultPlugin


