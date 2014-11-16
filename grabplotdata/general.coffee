#Compile:
# cjsx -b -p -c general.coffee > general.js
# https://github.com/jsdf/coffee-react

DataExporter = ->
    @uri = {
        excel: 'data:application/vnd.ms-excel;base64,',
        csv: 'data:application/csv;base64,'
    }

    @template = {
        excel: '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel" xmlns="http://www.w3.org/TR/REC-html40"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets><x:ExcelWorksheet><x:Name>{worksheet}</x:Name><x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions></x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]--></head><body><table>{table}</table></body></html>'
    }
    return

DataExporter::getContextForExportClickHandlerFromTextAreaForLink = (clicked_element_id,area_id)->
    return {
        link: document.getElementById(clicked_element_id)
        raw_data: document.getElementById(area_id).value
    }

DataExporter::getExportCSVClickHandlerFromTextAreaForLink = (clicked_element_id,area_id)->
    that = @
    wrapper = ()->
        context = that.getContextForExportClickHandlerFromTextAreaForLink(clicked_element_id,area_id)
        href_data = that.uri.csv+Base64.encode64(context.raw_data)
        context.link.href = href_data
        return
    return wrapper

DataExporter::_excell_format = (s,c) ->
    s.replace new RegExp("{(\\w+)}", "g"),(m,p)->
        c[p]

DataExporter::_prepare_csv_string_to_excell_table = (raw_data)->
    result = ""
    for line in raw_data.split('\n')
        result += "<tr>"
        cells = line.split(",")
        for cell in cells
            result += "<td>"+cell+"</td>"
        result += "</tr>"
    result

DataExporter::getExportExcelClickHandlerFromTextAreaForLink = (clicked_element_id,area_id,name)->
    that = @
    wrapper = ()->
        context = that.getContextForExportClickHandlerFromTextAreaForLink(clicked_element_id,area_id)

        excel_context = {
            worksheet: name or "WorkSheet0"
            table: that._prepare_csv_string_to_excell_table(context.raw_data)
        }
        href_data = that.uri.excel+Base64.encode64(that._excell_format(that.template.excel,excel_context))
        context.link.href = href_data
    return wrapper

DataExporter::getExportPNGClickHandlerFromDivForLink = (clicked_element_id,div_id)->
    wrapper = ->
        link = document.getElementById(clicked_element_id)
        div = document.getElementById(div_id)
        html2canvas div,
            onrendered:(canvas)->
                resultCanvasData = canvas.toDataURL('png')
                link.href=resultCanvasData
    return wrapper


LabeledInput = React.createClass
    getInitialState:->
        {
            value:@props.value or 0
            label:@props.label or @props.name
        }

    onChange: (event)->
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

        px = rgx1+((1.0*x)/Math.abs(rx2-rx1))*Math.abs(rgx2-rgx1)

        py = rgy1+(((1.0*(y))/Math.abs(ry2-ry1)))*Math.abs(rgy2-rgy1)

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
                    calibrated = true
                    alert "Done"
                    that.props.onChangeState null
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
                # alert point
                that.setState
                    points: points

    updateLabeledInput: (name,value)->
        state = @state
        state[name] = value
        @setState state

    showOwnPoints:->
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


ColorsPanel = React.createClass
    renderColors:(colors)->
        return <table>
                        <tr>        
                            {colors.palette.map (item,index)->

                                    <td className="swatch" 
                                        style={
                                            backgroundColor: "rgb(#{item[0]}, #{item[1]}, #{item[2]})"
                                            width:20
                                            height:20
                                        }
                                    ></td>
                            }
                        </tr>                            
                 </table>
    
    render:->
        colors = @props.colors
        if not (colors is null)
            return <div>
                <h3>Colors:</h3>
                    {@renderColors(colors)}
            </div>
        else
            return <div>
                <h3>Colors:</h3>
            </div>
            

WorkSpace = React.createClass
    getInitialState:->
        return {
            plot_url: null
            colors: null
        }

    getColors:(image,colorscount=15)->
        colorThief = new ColorThief()
        dominantColor = colorThief.getColor image
        palette = colorThief.getPalette image,colorscount

        return {
            dominantColor:dominantColor
            palette:palette
        }

    selectFileHandler:(event)->
        console.log "Selecting file..."
        that = @
        state.file_image = event.target.files[0]
        selected_file = document.getElementById("selected-file")
        reader = new FileReader()
        reader.onload = (e)->
            image = new Image()
            image.onload = ->
                console.log "Image selected"
                imgObj = new fabric.Image(image)
                imgObj.set
                    angle: 0
                    width: 600
                    height: 400
                    selectable: false
                state.canvas.centerObject(imgObj)
                state.canvas.add(imgObj)

                state.canvas.renderAll()

                that.setState
                    colors: that.getColors(image)

                that.render()

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
        console.log "Loading file..."
        that = @
        image = new Image()
        image.onload = ->
            imgObj = new fabric.Image(image)
            imgObj.set
                angle: 0
                width: 600
                height: 400
                selectable: false
                crossOrigin: ''
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
            <ColorsPanel colors={@state.colors} />
            <div id="image-container">
                <canvas  id="image" width="600px" height="400"></canvas>
            </div>
        </div>


PlotData = React.createClass

    getInitialState:->
        return {
            changed: new Date()
        }

    componentDidMount:->
        # making callback to make Root component know about self
        @props.tellRootAboutSelf(@)

    refresh:->
        console.log "refreshing ..."
        @setState
            changed: new Date()

    renderPlotPoints:->
        console.log "Rendering table"
        if @props.plotsDataProvider.state.plots.length == 0
            return

        plot = @props.plotsDataProvider.state.plots[@props.plotsDataProvider.state.activePlot].state
        csv_data = ""
        tableBody = <tbody>
                {
                    plot.points.map (item,index)->
                        csv_data += item.x+','+item.y+'\n'
                        return <tr>
                            <td>{index}</td>
                            <td>{item.x}</td>
                            <td>{item.y}</td>
                        </tr>
                }
        </tbody>
        return {
            tableBody:tableBody
            csv: csv_data
        }

    refreshPlot:->
        # console.log "drawing plot"
        if @props.plotsDataProvider.state.plots.length == 0
            return
        currentPlot = @props.plotsDataProvider.state.plots[@props.plotsDataProvider.state.activePlot].state


        calibrateData = currentPlot.calibrateData
        points = currentPlot.points

        result_data = [ ]
        graphic_points = []

        for point in points
            graphic_points.push [point.x,point.y]
        if graphic_points.length == 0
            return
        result_data.push graphic_points

        # options =
        #     xaxis:
        #         min: calibrateData.x1
        #         max: calibrateData.x2
        #     yaxis:
        #         min: calibrateData.y1
        #         max: calibrateData.y2
        # console.log result_data
        # console.log options

        $.plot(
               $("#plot-graphic"),
               result_data,
               # options
               )
        return

    getCurrentPlotName:->
        console.log @props.plotsDataProvider.state.plots
        console.log @props.plotsDataProvider.state.activePlot
        if @props.plotsDataProvider.state.plots[@props.plotsDataProvider.state.activePlot] is not undefined
            return @props.plotsDataProvider.state.plots[@props.plotsDataProvider.state.activePlot].state.name
        else
            return "untitled"

    render: ()->
        rendered_table = @renderPlotPoints()
        return <div className="row-fluid">
            <h3>Plot-data:</h3>
            <ul className="nav nav-tabs" role="tablist">
                <li className="active"><a role="tab" data-toggle="tab" href="#table">Table</a></li>
                <li><a role="tab" data-toggle="tab" href="#csv">Export</a></li>
                <li><a role="tab" data-toggle="tab" href="#plot">Plot</a></li>
            </ul>
            <div className="tab-content">
                <div className="tab-pane active" id="table">
                    <table id="plot-points" className="table table-bordered">
                        <thead>
                            <th>Index</th>
                            <th>X</th>
                            <th>Y</th>
                        </thead>
                        {rendered_table.tableBody if rendered_table}
                    </table>
                </div>
                <div className="tab-pane" id="csv">
                    <textarea id="export_data" value={rendered_table.csv if rendered_table}>
                    </textarea>
                    <br/>
                    <a
                        id="csv_export_link"
                        className="btn btn-small btn-primary"
                        download={@getCurrentPlotName()+'.csv'}
                        onClick={new DataExporter().getExportCSVClickHandlerFromTextAreaForLink "csv_export_link","export_data"
                        }
                    >Export as CSV</a>
                    <a
                        id="excel_export_link"
                        className="btn btn-small btn-primary"
                        download={@getCurrentPlotName()+'.xls'}
                        onClick={new DataExporter().getExportExcelClickHandlerFromTextAreaForLink "excel_export_link", "export_data"
                        }
                    >Export as Excel</a>
                </div>
                <div className="tab-pane" id="plot" >
                    <div id="plot-graphic" style={
                                        width:500,
                                        height:300
                                        }>
                    </div>
                    {@refreshPlot()}
                    <a
                        id="png_export_link"
                        className="btn btn-small btn-primary"
                        download={@getCurrentPlotName()+'.png'}
                        onClick={new DataExporter().getExportPNGClickHandlerFromDivForLink "png_export_link","plot-graphic"
                        }
                    >Export as PNG</a>
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

    getPlotDataInstance: (instance) ->
        @setState
            plotDataInstance: instance

    onChangeState:(state)->
        console.log state
        @setState
            state:state

    onActivatePlot:(index)->
        @state.plots[@state.activePlot].setState
            activated: false
        @setState
            activePlot: index

    onAfterDidMountPlot:(plot_data)->
        plots = @state.plots
        plots.push plot_data
        @setState
            plots: plots

        #copy calibrate data to new plot
        parent_plot = @state.plots[@state.activePlot]

        parent_calibrated = parent_plot.state.calibrated
        parent_calibrateData = new Object(parent_plot.state.calibrateData)

        plot_data.setState
            calibrated: parent_calibrated
            calibrateData: parent_calibrateData

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
        @state.plotDataInstance.refresh()

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

    detectplot:(x,y)->
        console.log "detecting ..."
        context = state.canvas.getContext("2d")
        image_data = context.getImageData x,y,1,1
        data = image_data.data
        console.log data
        d = [data[0],data[1],data[2]].join(",")
        color = new fabric.Color('rgb('+d+')')
        alert color.toHex()
        console.log "Image data="

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
                @detectplot(x,y)

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
                    <PlotData
                        tellRootAboutSelf={@getPlotDataInstance}
                        plotsDataProvider={@}
                    />
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
