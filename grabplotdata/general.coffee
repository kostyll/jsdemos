#Compile:
# cjsx -b -p -c general.coffee > general.js
# https://github.com/jsdf/coffee-react

State = () ->
    @file_image = null
    @state = "start"
    @possible_states = [
        "start"
        "uploaded"
        "select-points"
        "calibrate"
    ]
    @image_left = 0
    @image_top = 0
    @image_width = 0
    @image_height = 0
    @canvas = null
    @ctx = 0

State::changeState = (state)->
    that = @
    that.state = state
    console.log "Changing state to "+String(state)

State::change_image = (image_html_el) ->
    that = @
    that.image_left = image_html_el.offsetLeft
    that.image_top = image_html_el.offsetTop
    that.image_width = image_html_el.width
    that.image_height = image_html_el.height
    console.log @

State::get_image_coordinates_from_client = (clientX,clientY) ->
    that = @
    x = clientX - that.image_left
    y = clientY - that.image_top
    return [x,y]

state = new State()

image_click_handler = (e) ->
    console.log "Image clicked"
    console.log state.get_image_coordinates_from_client(e.clientX,e.clientY)

prepare = ()->
    document.getElementById("selected-file").addEventListener "change", (event)->
        state.file_image = event.target.files[0]
        selected_file = document.getElementById("selected-file")
        source_image = document.getElementById("image")
        console.log "Uploading image"
        console.log state.file_image
        reader = new FileReader()
        reader.onload = (e)->
            image = new Image()
            canvas = document.createElement("canvas")

            image.id ="image-data"
            image.onload = ->
                canvas.width = image.width
                canvas.height = image.height
                ctx = canvas.getContext("2d")
                ctx.drawImage(image,0,0)
                while source_image.firstChild
                    source_image.removeChild(source_image.firstChild)
                source_image.appendChild(canvas)
                state.change_image(canvas)
                state.canvas = canvas
                state.context = ctx
                return

            image.src = reader.result
            canvas.onclick = image_click_handler
            return
        reader.readAsDataURL(state.file_image)
        return
    return

document.onready = prepare
