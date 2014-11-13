#Compile:
# cjsx -b -p -c general.coffee > general.js
# https://github.com/jsdf/coffee-react

LabeledInput = React.createClass
    getInitialState:->
        {
            value:@props.value or 0
            label:@props.label or @props.name
        }

    onChange: (event)->
        # console.log event
        # console.log event.target.value
        @setState
            value: event.target.value
        @props.onChange(@props.name,event.target.value)
        return

    render:->
        <form className="form-horizontal">
            <div className="control-group">
                <label className="control-label" for={@props.id}>{@state.label}</label>
                <div className="controls">
                    <input type="text" className={@props.className+" input-small"} id={@props.id} onChange={@onChange} placeholder={@props.value} />
                </div>
            </div>
        </form>


PlotOptionsForm = React.createClass
    getInitialState: ()->
        console.log "Plot props"
        console.log @props
        return {
            activated: @props.activated
            color: null
            calibrated:@props.calibrated
            calibrateData:
                currentIndex:0
                x1:0
                x2:0
                y1:0
                y2:0
                pointObjects:[]
            gx1:0
            gx2:0
            gy1:0
            gy2:0
            points:[]
            name: @props.name or ""
            title: @props.title or "untitled"
        }

    componentDidMount:->

        @props.onAfterDidMountPlot(@)

    HeadClickHandler:->
        activated = @state.activated
        if activated == true
            activated = false
        else
            activated = true
        @setState
            activated: activated
        @props.onActivatePlot(@props.id)
        return

    handleSelectColor: (event)->
        console.log "Selecting color"
        console.log event

    transformPixelToPoint: (pixel)->
        # A|-------------X1----------------X2--------|C
        # D|-----Y1------------------------------Y2--|E
        w = 600
        h = 400
        x = pixel.x
        y = h-pixel.y

        # console.log pixel

        s = @state
        c = s.calibrateData
        x1 = Number c.x1
        x2 = Number c.x2
        y1 = Number c.y1
        y2 = Number c.y2

        gx1 = Number s.gx1
        gx2 = Number s.gx2
        gy1 = Number s.gy1
        gy2 = Number s.gy2

        # |AC|/|ACpx| = |X1X2|/|X1X2px|
        # |AC| = |ACpx|*|X1X2|/|X1X2px|

        # |AX1| / |AX1px| = |AC|/w
        # |AX1| = |AC|*|AX1px|/w

        # |X2C|/|X2Cpx| = |AC|/w
        # |X2C| = |AC|*|X2Cpx|/w
        AC = (1.0*(gx2-gx1))*w/(x2-x1)
        # console.log "AC"
        # console.log AC

        AX1px = (x1-0)
        X2Cpx = (w-x2)

        AX1 = AC*AX1px/w
        X2C = AC*X2Cpx/w

        # |DE|/|DEpx| = |Y1Y2|/|Y1Y2px|
        # |DE| = |DEpx|*|Y1Y2|/|Y1Y2px|

        # |DY1|/|DY1px| = |DE|/h
        # |DY1| = |DY1px|*|DE|/h

        # |Y2E|/|Y2Epx| = |DE|/h
        # |Y2E| = |Y2Epx| * |DE| /h

        DE = (1.0*(gy2-gy1))*h/(y2-y1)

        DY1px = (y1-0)
        Y2Epx = (h-y2)

        DY1 = DE * DY1px / h
        Y2E = DE * Y2Epx / h

        rx1 = 0
        rx2 = w

        ry1 = 0
        ry2 = h

        rgx1 = gx1-AX1
        rgx2 = gx2+X2C

        rgy1 = gy1-DY1
        rgy2 = gy2+Y2E

        # console.log [
        #     x1,x2,y1,y2
        # ]

        # console.log [
        #     rx1,rx2,ry1,ry2
        # ]

        # console.log [
        #     gx1,gx2,gy1,gy2
        # ]

        # console.log [
        #     rgx1,rgx2,rgy1,rgy2
        # ]

        px = rgx1+((1.0*x)/Math.abs(rx2-rx1))*Math.abs(rgx2-rgx1)

        py = rgy1+(((1.0*(y))/Math.abs(ry2-ry1)))*Math.abs(rgy2-rgy1)
        # console.log [
        #     px,py
        # ]
        return {
                x:px
                y:py
            }

    handleCalibrate: (event) ->
        that = @
        console.log "Calibrate"
        console.log event
        @props.onChangeState
            name: "calibrate"
            callback: (x,y,obj)->
                console.log arguments
                calibrateData = that.state.calibrateData
                index = calibrateData.currentIndex
                calibrated = false
                if index == 0
                    for point in calibrateData.pointObjects
                        state.canvas.remove(point)
                    calibrateData.pointObjects = []
                    calibrateData.x1 = x
                    calibrateData.pointObjects.push obj
                else if index == 1
                    calibrateData.x2 = x
                    calibrateData.pointObjects.push obj
                else if index == 2
                    calibrateData.y1 = 400-y
                    calibrateData.pointObjects.push obj
                else if index == 3
                    calibrateData.y2 = 400-y
                    calibrateData.pointObjects.push obj
                index = index + 1
                if index == 4
                    index = 0
                    that.props.onChangeState null
                    console.log "on changeState null"
                    calibrated = true
                    alert "Done"
                    that.props.onChangeState null
                    console.log "changed state to null"
                calibrateData.currentIndex = index
                that.setState
                    calibrated: calibrated
                    calibrateData:calibrateData

    handleDetectPoints:(event)->
        console.log "Detecting points"
        @props.onChangeState
            name: "detect"
            callback: ()->
                console.log arguments

    handleChoisePoints:(event)->
        console.log "Choising points"
        that = @
        if that.state.calibrated == false
            alert "Not calibrated"
            return
        @props.onChangeState
            name: "select"
            callback: (x,y,obj)->
                if that.state.calibrated == false
                    alert "Not calibrated"
                    return
                console.log arguments
                points = that.state.points
                pixel = {
                    x:x
                    y:y
                }
                point = that.transformPixelToPoint(pixel)
                point.obj = obj
                points.push point
                console.log "Point"
                console.log point
                # alert point
                that.setState
                    points: points

    updateLabeledInput: (name,value)->
        state = @state
        state[name] = value
        @setState state

    showOwnPoints:->
        console.log "Showing points"
        points = @state.points
        for point in points
            # state.canvas.add(point.obj)
            # console.log ""
            point.obj.bringToFront()
        points = @state.calibrateData.pointObjects
        for point in points
            point.bringToFront()
        if state.canvas is not null
            state.canvas.renderAll()

    hideOwnPoints:->
        console.log "Hiding points"
        points = @state.points
        for point in points
            # state.canvas.remove(point.obj)
            # point.obj.setVisible(false)
            point.obj.sendBackwards(true)
        points = @state.calibrateData.pointObjects
        for point in points
            point.sendBackwards()
        if state.canvas is not null
            state.canvas.renderAll()

    renderHead:->

        <button className="btn btn-primary" onClick={@HeadClickHandler}>{@state.name}</button>

    render: () ->
        s = @state
        console.log @state.points
        if s.activated == true
            @showOwnPoints()
            return <div>
                <LabeledInput label="Plot name" id={@props.id} name={"name"} value={@state.name} onChange={@updateLabeledInput}/>
                <button className="btn btn-small" onClick={@handleSelectColor}>Select color</button>
                <button className="btn btn-small" onClick={@handleCalibrate}>Calibrate</button>
                <button className="btn btn-small" onClick={@handleDetectPoints}>Detect points</button>
                <button className="btn btn-small" onClick={@handleChoisePoints}>Choise plot points</button>
                <LabeledInput id={@props.id} name="gx1" value={s.gx1} onChange={@updateLabeledInput}/>
                <LabeledInput id={@props.id} name="gx2" value={s.gx2} onChange={@updateLabeledInput}/>
                <LabeledInput id={@props.id} name="gy1" value={s.gy1} onChange={@updateLabeledInput}/>
                <LabeledInput id={@props.id} name="gy2" value={s.gy2} onChange={@updateLabeledInput}/>
            </div>
        else
            @hideOwnPoints()
            return <div>
                {@renderHead()}
            </div>


ToolBox = React.createClass
    getInitialState:->
        console.log @props
        items = []
        @props.items.forEach (item,index,arr) ->
            items.push
                index: index
                value: item

        return {
            activeItem: 0
            items: items
        }

    componentDidMount:->

        console.log @props

    addNewPlot:->
        items = @state.items
        items.push
            index: items.length
            value: "New plot"
        @setState
            items: items

    render:->
        that = @
        <div id="toolbox">
            <h3>Toolbox:</h3>
            <button className="btn btn-large btn-primary" onClick={@addNewPlot}>Add new plot</button>
            {@state.items.map (item)->
                return <PlotOptionsForm
                    id={item.index}
                    name={item.value}
                    onAfterDidMountPlot={that.props.onAfterDidMountPlot}
                    onActivatePlot={that.props.onActivatePlot}
                    activated={item.index==that.props.activePlot}
                    onChangeState={that.props.onChangeState}
                    calibrated={false}
                />
            }
        </div>


WorkSpace = React.createClass
    getInitialState:->
        return {
            plot_url: null
        }
    selectFileHandler:(event)->
        that = @
        state.file_image = event.target.files[0]
        selected_file = document.getElementById("selected-file")
        console.log "Uploading image"
        console.log state.file_image
        reader = new FileReader()
        reader.onload = (e)->
            image = new Image()
            image.onload = ->
                imgObj = new fabric.Image(image)
                imgObj.set
                    angle: 0
                    width: 600
                    height: 400
                    selectable: false
                state.canvas.centerObject(imgObj)
                state.canvas.add(imgObj)

                state.canvas.renderAll()
                that.props.onImageLoad(imgObj)
                return

            image.src = reader.result
            return
        reader.readAsDataURL(state.file_image)
        return

    onChagePlotUrl:(event)->
        @setState
            plot_url:event.target.value

    onLoadImagePlot:->
        that = @
        console.log "Loading image plot"
        console.log @state.plot_url
        image = new Image()
        image.onload = ->
            console.log "Image loaded"
            imgObj = new fabric.Image(image)
            imgObj.set
                angle: 0
                width: 600
                height: 400
                selectable: false
            state.canvas.centerObject(imgObj)
            state.canvas.add(imgObj)
            state.canvas.renderAll()
            that.props.onImageLoad(imgObj)
            return
        image.src = @state.plot_url
        return

    componentDidMount:->
        document.getElementById("selected-file").addEventListener "change",@selectFileHandler
        @props.onAfterDidMountWorkSpace(@)

    render: ()->
        <div className="row-fluid">
            <h3>Workspace:</h3>
            <ul className="nav nav-tabs" role="tablist">
                <li className="active"><a role="tab" data-toggle="tab" href="#source_image_file">File</a></li>
                <li><a role="tab" data-toggle="tab" href="#source_image_url">URL</a></li>
            </ul>
            <div className="tab-content">
                <div className="tab-pane active" id="source_image_file">
                    <span className="btn btn-file">
                        <input id="selected-file" type="file" className="form-control"/>
                    </span>
                </div>
                <div className="tab-pane" id="source_image_url">
                    <form className="form-horizontal">
                        <div className="control-group">
                            <label className="control-label" for="source_url">Plot url</label>
                            <div className="controls">
                                <input type="text" className="input"} id="source_url" onChange={@onChagePlotUrl} placeholder="http://imageurl" />
                                <a className="btn btn-small btn-primary" onClick={@onLoadImagePlot}>Load</a>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
            <div id="image-container">
                <canvas  id="image" width="600px" height="400"></canvas>
            </div>
        </div>


PlotData = React.createClass
    render: ()->
        <div className="row-fluid">
            <h3>Plot-data:</h3>
            <ul className="nav nav-tabs" role="tablist">
                <li className="active"><a role="tab" data-toggle="tab" href="#table">Table</a></li>
                <li><a role="tab" data-toggle="tab" href="#plot">Plot</a></li>
            </ul>
            <div className="tab-content">
                <div className="tab-pane active" id="table">
                    LALALA
                </div>
                <div className="tab-pane" id="plot">
                    LALALA
                </div>
            </div>
        </div>


DemoPage = React.createClass
    getInitialState: ()->
        {
            activePlot:0
            plots: []
            lastplot: 0
            workspace: null
            putNewPoints: true
            state:null
            image:null
        }

    onChangeState:(state)->
        console.log state
        @setState
            state:state

    onActivatePlot:(index)->
        console.log "Activating..."
        console.log index
        @state.plots[@state.activePlot].setState
            activated: false
        @setState
            activePlot: index

    onAfterDidMountPlot:(plot_data)->
        plots = @state.plots
        plots.push plot_data
        @setState
            plots: plots
        # console.log "Plot added"
        # console.log @state

        #copy calibrate data to new plot
        parent_plot = @state.plots[@state.activePlot]
        # console.log parent_plot

        parent_calibrated = parent_plot.state.calibrated
        parent_calibrateData = new Object(parent_plot.state.calibrateData)

        # console.log "plot_data=,parent_calibrated=,parent_calibrateData"
        # console.log plot_data
        # console.log parent_calibrated
        # console.log parent_calibrateData

        plot_data.setState
            calibrated: parent_calibrated
            calibrateData: parent_calibrateData

        # console.log "Compare..."
        # console.log parent_plot.state.calibrateData is plot_data.state.calibrateData

    onAfterDidMountWorkSpace:(workspace)->
        @setState
            workspace:workspace

    onImageLoad:(image)->
        @setState
            image:image
        for plot in @state.plots
            plot.setState
                calibrated: false
        return

    switchOnPlotPointsPut:->
        @setState
            putNewPoints:true

    switchOffPlotPointsPut:->
        @setState
            putNewPoints:false

    putNewPoints:(flag)->
        if flag == true
            @switchOnPlotPointsPut()
        else
            @switchOffPlotPointsPut

    putSelectedPoint:(x,y,callback)->
        R = 3
        circle = new fabric.Circle
            left : x - R // 2
            top : y - R //2
            radius: R
            fill: "red"
            selectable: false
        state.canvas.add(circle)
        callback x,y,circle

    putCalibratedPoint:(x,y,callback)->
        R = 5
        rect = new fabric.Rect
            left : x - R // 2
            top : y - R // 2
            width: 2 * R
            height: 2 * R
            fill: "green"
            selectable: false
        state.canvas.add(rect)
        callback x,y,rect

    image_click_handler: (e) ->
        console.log @state
        if @state.image != null
            console.log "Image clicked"
            console.log e
            e = e.e
            console.log e
            coordinate = state.get_image_coordinates_from_client(e.clientX,e.clientY)
            x = coordinate[0]
            y = coordinate[1]

            s = @state.state

            if s is null
                console.log "ups ..."

            else if s.name=="calibrate"
                # put point to calibrate
                @putCalibratedPoint(x,y,s.callback)
            else if s.name=="detect"
                # detect plot
                console.log "detecting ..."

            else if s.name == "select"
                # select custom points
                console.log "selecting ..."
                @putSelectedPoint(x,y,s.callback)
            else if s == null
                #
            else
                console.log "Ups.."

        else
            console.log "Not image loaded"
            alert "Not image loaded"

    componentDidMount:->
        state.canvas = new fabric.Canvas("image")
        state.image_left = state.canvas._offset.left
        state.image_top = state.canvas._offset.top
        state.source_image = document.getElementById("image")
        state.canvas.on('mouse:down',@image_click_handler)
        console.log @state

    render: ()->
        <div className="row-fluid">
                <div className="span10">
                    <WorkSpace
                        onAfterDidMountWorkSpace={@onAfterDidMountWorkSpace}
                        onImageLoad={@onImageLoad}
                    />
                    <PlotData />
                </div>
                <div className="span2">
                    <ToolBox
                        activePlot=@state.activePlot
                        items={@props.items}
                        onAfterDidMountPlot={@onAfterDidMountPlot}
                        onActivatePlot={@onActivatePlot}
                        onChangeState={@onChangeState}
                    />
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


state = new State()


prepare = ()->
    items = ["Untitled0",]
    React.render(<DemoPage items={items}/>,document.getElementById("container"))

document.onready = prepare
