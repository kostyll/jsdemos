#Compile:
# cjsx -b -p -c general.coffee > general.js
# https://github.com/jsdf/coffee-react

NumberInput = React.createClass
    getInitialState:->
        {
            value:0
        }

    onChange: (event)->
        console.log event
        @setStage
            value: event.target.value
        return

    render:->
        <div className="form-group">
            <label for={@props.name}>{@props.name}</label>
            <input className={@props.className+" form-control"} onChange={@onChange} placeholder="0" value={@props.value}/>
        </div>

PlotOptionsForm = React.createClass
    getInitialState: ()->
        {
            activated: false
            color: null
            x1:0
            x2:0
            y1:0
            y2:0
            gx1:0
            gx2:0
            gy1:0
            gy2:0
            points:[]
            name: @props.name or ""
            title: @props.title or "untitled"
        }

    render: () ->
        items = [@state.x1,@state.x2,@state.y1,@state.y2]
        # console.log items
        return <div>
            <p>Options Form {@state.name}</p>
            {items.map (number)->
                return <NumberInput name=number className="", value={number}/>
                }
        </div>


ToolBox = React.createClass
    render: ()->
        <p> toolbox stub </p>
        <div>
            {@props.items.map (item)->
                return <PlotOptionsForm name={item}/>
            }
        </div>


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
    @image_matrix = null
    @source_image = null
    @canvas = null

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
    x = clientX - @image_left
    y = clientY - @image_top
    return [x,y]

ImageMatrix = (data) ->
    @source_data = data
    @width = data.width
    @height = data.height

    # console.log @

state = new State()

image_click_handler = (e) ->
    console.log "Image clicked"
    console.log e
    e = e.e
    # console.log e
    coordinate = state.get_image_coordinates_from_client(e.clientX,e.clientY)
    x = coordinate[0]
    y = coordinate[1]

    R = 3

    circle = new fabric.Circle
        left : x - R // 2
        top : y - R //2
        radius: R
        fill: "red"
    state.canvas.add(circle)


prepare = ()->
    items = ["item1","item2","item3"]
    React.render(<ToolBox items={items}/>,document.getElementById("toolbox"))

    state.canvas = new fabric.Canvas("image")
    state.image_left = state.canvas._offset.left
    state.image_top = state.canvas._offset.top
    state.canvas.on('mouse:down',image_click_handler)
    state.source_image = document.getElementById("image")
    document.getElementById("selected-file").addEventListener "change", (event)->
        state.file_image = event.target.files[0]
        selected_file = document.getElementById("selected-file")
        console.log "Uploading image"
        console.log state.file_image
        reader = new FileReader()
        reader.onload = (e)->
            image = new Image()

            image.id ="image-data"
            image.onload = ->
                imgObj = new fabric.Image(image)
                imgObj.set
                    angle: 0
                    width: 600
                    height: 400
                state.canvas.centerObject(imgObj)
                state.canvas.add(imgObj)

                state.canvas.renderAll()
                return

            image.src = reader.result
            return
        reader.readAsDataURL(state.file_image)
        return
    return

document.onready = prepare
