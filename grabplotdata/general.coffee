#Compile:
# cjsx -b -p -c general.coffee > general.js
# https://github.com/jsdf/coffee-react

NumberInput = React.createClass
    getInitialState:->
        {
            value:@props.value or 0
        }

    onChange: (event)->
        # console.log event
        # console.log event.target.value
        @setState
            value: event.target.value
        return

    render:->
        <form className="form-horizontal">
            <div className="control-group">
                <label className="control-label" for={@props.id}>{@props.name}</label>
                <div className="controls">
                    <input type="number" className="input-small" id={@props.id} onChange={@onChange} placeholder={@props.value} />
                </div>
            </div>
        </form>


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
        # items = []
        # for prop in Object.keys(@state)
        #     if prop[0] == "x" or prop[0] == "y" or prop[0] == "g"
        #         items.push
        #             name: prop
        #             value: @state[prop]

        # console.log items
        s = @state
        return <div>
            <p>Options Form {@state.name}</p>
            <NumberInput id={@props.id} name="gx1" value={s.gx1}/>
            <NumberInput id={@props.id} name="gx2" value={s.gx2}/>
            <NumberInput id={@props.id} name="gy1" value={s.gy1}/>
            <NumberInput id={@props.id} name="gy2" value={s.gy2}/>
        </div>


ToolBox = React.createClass
    getInitialState:->
        items = []
        @props.items.forEach (item,index,arr) ->
            items.push
                index: index
                value: item

        console.log @props.parent.state.plots

        {
            activeItem:0
            items: items
        }
    render: ()->
        <div id="toolbox">
            <h3>Toolbox:</h3>
            {@state.items.map (item)->
                return <PlotOptionsForm id={item.index} name={item.value}/>
            }
        </div>


WorkSpace = React.createClass
    selectFileHandler:(event)->
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

    componentDidMount:->
        document.getElementById("selected-file").addEventListener "change",@selectFileHandler

    render: ()->
        <div className="row-fluid">
            <h3>Workspace:</h3>
            <div id="workspace"></div>
            <span className="btn btn-file">
                <input id="selected-file" type="file" className="form-control"/>
            </span>
            <hr/>
            <div id="image-container">
                <canvas  id="image" width="600px" height="400"></canvas>
            </div>
        </div>


PlotData = React.createClass
    render: ()->
        <div className="row-fluid">
            <h3>Plot-data:</h3>
            <div id="plot-data"></div>
        </div>


DemoPage = React.createClass
    getInitialState: ()->
        {
            activePlot: 0
            plots: []
        }

    image_click_handler: (e) ->
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

    componentDidMount:->
        state.canvas = new fabric.Canvas("image")
        state.image_left = state.canvas._offset.left
        state.image_top = state.canvas._offset.top
        state.source_image = document.getElementById("image")
        state.canvas.on('mouse:down',@image_click_handler)

    render: ()->
        <div className="row-fluid">
                <div className="span10">
                    <WorkSpace />
                    <PlotData />
                </div>
                <div className="span2">
                    <ToolBox items={@props.items} parent={@} />
                </div>
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


prepare = ()->
    items = ["item1","item2","item3"]
    React.render(<DemoPage items={items}/>,document.getElementById("container"))

document.onready = prepare
