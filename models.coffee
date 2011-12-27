crypto = require("crypto")
Item = undefined
Administrator = undefined
LoginToken = undefined
Category = undefined

extractKeywords = (text) ->
  return []  unless text
  #text.join('/r/n')+'' if text.push
  if text.push
    trry = []
    for i in text
      trry.push(i) if typeof(i)=='string'
    trry=trry.join('/r/n')
  else
    trry = text

  trry.split(/\s+/).filter((v) ->
    v.length > 2
  ).filter (v, i, a) ->
    a.lastIndexOf(v) is i

defineModels = (mongoose, fn) ->
  validatePresenceOf = (value) ->value and value.length
  Schema = mongoose.Schema
  ObjectId = Schema.ObjectId

  Category = new Schema
    title:String
    created_at:Date
    administrator:
      type: ObjectId
      ref: 'Administrator'

  Category.virtual("id").get ->
    @_id.toHexString()
  
  Category.pre "save", (next) ->
    @title = @title.trim()
    next()

  Exhibitor = new Schema
    created_at:
      type:Date
      index:true
    title:
      type:String
      index:true
    pinyin_short:
      type:String
      index:true
    administrator: 
      type: ObjectId
      ref: 'Administrator'
    pinyin:String
    summary:String
    image_url:String
    web_url:String


  Exhibitor.virtual("id").get ->
    @_id.toHexString()
  
  Exhibitor.pre "save", (next) ->
    @title = @title.trim()
    @summary = @summary.trim()
    @web_url = @web_url.trim() if @web_url
    next()

  Item = new Schema
    created_at:
      type:Date
      index:true
    sold:
      type:Boolean
      default:false
      index:true 
    category:
      type:ObjectId
      ref:'Category'
      index:true
    exhibitor:
      type:ObjectId
      ref:'Exhibitor'
      index:true
    administrator:
      type: ObjectId
      ref: 'Administrator'
    price: 
      type:Number
      min:0
    title:String
    image_url:String
    summary:String
    data: [ String ]
    size:String
    delivery:String
    update_at:Date
    sold_at:Date
    keywords: [ String ]
    pay_url:String
    pay_processing:
      type:Boolean
      default:false
    pay_at:Date
    ticket:ObjectId

  Item.virtual("id").get ->
    @_id.toHexString()

  Item.pre "save", (next) ->
    #auto make a keywords for search
    #@keywords = extractKeywords(@data)
    #auto change sold status by pay_processing
    @sold = true if (@pay_processing == true || @pay_at)
    @sold = false if (@pay_processing == false && !@pay_at)
    #trim
    @title = @title.trim()
    @summary = @summary.trim() if @summary
    #@data = @data.trim()
    @size = @size.trim() if @size
    @delivery = @delivery.trim() if @delivery
    next()

  Administrator = new Schema
    email:
      type: String
      validate: [ validatePresenceOf, "an email is required" ]
      index:
        unique: true
    hashed_password: String
    salt: String

  Administrator.virtual("id").get ->
    @_id.toHexString()

  Administrator.virtual("password").set((password) ->
    @_password = password
    @salt = @makeSalt()
    @hashed_password = @encryptPassword(password)
  ).get ->
    @_password

  Administrator.method "authenticate", (plainText) ->
    @encryptPassword(plainText) is @hashed_password

  Administrator.method "makeSalt", ->
    Math.round((new Date().valueOf() * Math.random())) + ""

  Administrator.method "encryptPassword", (password) ->
    crypto.createHmac("sha1", @salt).update(password).digest "hex"

  Administrator.pre "save", (next) ->
    unless validatePresenceOf(@password)
      next new Error("Invalid password")
    else
      next()

  LoginToken = new Schema
    email:
      type: String
      index: true
    series:
      type: String
      index: true
    token:
      type: String
      index: true

  LoginToken.method "randomToken", ->
    Math.round((new Date().valueOf() * Math.random())) + ""

  LoginToken.pre "save", (next) ->
    @token = @randomToken()
    @series = @randomToken()  if @isNew
    next()

  LoginToken.virtual("id").get ->
    @_id.toHexString()

  LoginToken.virtual("cookieValue").get ->
    JSON.stringify
      email: @email
      token: @token
      series: @series
  
  mongoose.model "Category", Category
  mongoose.model "Exhibitor", Exhibitor
  mongoose.model "Item", Item
  mongoose.model "Administrator", Administrator
  mongoose.model "LoginToken", LoginToken
  fn()

exports.defineModels = defineModels