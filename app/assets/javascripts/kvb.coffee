class Kvb
  data = null
  filter = "bahn"
  search = $(".searchField").val() || ""

  load: (callback) =>
    if data == null
      $.getJSON "/assets/kvb_stops.json", (json) =>
        data = json
        for station in data
          station["type"] = @analyseType station["points"]
        data = data.sort (a,b) =>
          return if a["station"] > b["station"] then 1 else -1

        callback data
    else
      callback data

  distance: (lat1, lon1, lat2, lon2) ->
    R = 6371 # KM
    dLat = (lat2-lat1).toRad()
    dLon = (lon2-lon1).toRad()
    lat1 = lat1.toRad()
    lat2 = lat2.toRad()

    a = Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2)
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    d = R * c

  distanceToPoint: (lat1, lon1, station) =>
    distance = Number.MAX_VALUE
    for point in station["points"]
      d =  @distance(lat1, lon1, parseFloat(point["lat"]), parseFloat(point["long"]))
      distance = d if d < distance
    distance

  analyseType: (points) =>
    isBus = false
    isBahn = false
    for point in points
      isBus  = true if point["type"] == "bus"
      isBahn = true if point["type"] == "bahn"
    return "both" if isBus && isBahn
    return "bus" if isBus
    return "bahn"

  sortByDistance: (position)=>
    for station in data
      station["distance"] = @distanceToPoint parseFloat(position.coords.latitude), parseFloat(position.coords.longitude), station

    data = data.sort (a,b) =>
      return if a["distance"] > b["distance"] then 1 else -1

    @fillList()

  updateFilter: (newType) =>
    filter = newType
    @fillList()
    $(".result").animate({ scrollTop: 0 }, "fast");

  updateSearch: (newSearch) =>
    return if newSearch == search
    search = newSearch.toLowerCase()
    @fillList()
    $(".result").animate({ scrollTop: 0 }, "fast");

  distanceToString: (distance) =>
    if (distance == Number.MAX_VALUE)
      ""
    else if (distance < 1)
      "#{Math.round(distance * 1000)} m"
    else
      "#{distance.toFixed(2)} km"

  fillList: =>
    $(".result").empty()
    for i in data
      if (i["type"] == filter || i["type"] == "both" || filter == "both") && (search == "" || i["station"].toLowerCase().indexOf(search) != -1)
        distance = if i["distance"]? then "<span class='distance'>#{@distanceToString(i["distance"])}</span>" else ""
        $(".result").append("<li><a href='http://www.kvb-koeln.de/qr/#{i["kvb-id"]}'>#{i["station"]}#{distance}</a></li>")

if !Number.prototype.toRad?
  Number.prototype.toRad = ->
    return this * Math.PI / 180

$ ->
  kvb = new Kvb
  kvb.load (data)->
    if navigator.geolocation?
      navigator.geolocation.getCurrentPosition kvb.sortByDistance, kvb.fillList
    else
      kvb.fillList

  $(".busFilterLink").click ->
    $(".selectedFilter").removeClass("selectedFilter")
    $(".busFilterLink").addClass("selectedFilter")
    kvb.updateFilter "bus"

  $(".bahnFilterLink").click ->
    $(".selectedFilter").removeClass("selectedFilter")
    $(".bahnFilterLink").addClass("selectedFilter")
    kvb.updateFilter "bahn"

  $(".bothFilterLink").click ->
    $(".selectedFilter").removeClass("selectedFilter")
    $(".bothFilterLink").addClass("selectedFilter")
    kvb.updateFilter "both"

  $(".searchField").keyup ->
    kvb.updateSearch $(".searchField").val()

  $(".searchField").change ->
    kvb.updateSearch $(".searchField").val()

  $(".delete").click ->
    $(".searchField").val("")
    kvb.updateSearch ""

  $(".impressumOpen a").click ->
    $(".impressum").fadeIn(150)

  $(".impressum .close").click ->
    $(".impressum").fadeOut(150)

  setTimeout ( ->
    kvb.updateSearch $(".searchField").val()
  ), 100
