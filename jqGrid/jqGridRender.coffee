_ = require 'underscore'
jQuery = require 'jquery'

jqGridEdit = require './jqGridEdit'
JqGridEdit = jqGridEdit.JqGridEdit

class JqGridRender extends JqGridEdit
	colModel: []
	runSetCommands: true 
	gridMethods: []
	customCode: ""

	navigator: false
	toolbarfilter: true
	inlineNav: false 

	export: true 
	exportfile: 'exportdata.xml' 

	pdffile: 'exportdata.pdf' 

	csvfile: 'exportdata.csv' 
	csvsep: '' 
	csvsepreplace: "" 

	sharedEditOptions: false 
	sharedAddOptions: false 
	sharedDelOptions: false 

	gridOptions: 
		#width: 650
		hoverrows: false   
		viewrecords: true
		rowList: [10,20,30]
		###
		jsonReader:
			repeatitems: false
			subgrid:
				repeatitems:false
		xmlReader:
			repeatitems:false
			subgrid:
				repeatitems:false
		###
		gridview:true
		
	navOptions:
		edit: true, add: true, del:true, search: true, refresh: true, view: false, excel: true, pdf: false, csv: false, columns:false
  	
	editOptions: 
		drag:true, resize:true, closeOnEscape: true, dataheight: 150, errorTextFormat:"function(r){ return r.responseText}"

	addOptions: 
		drag:true, resize:true, closeOnEscape: true, dataheight: 150, errorTextFormat:"function(r){ return r.responseText}"

	delOptions: 
		errorTextFormat:"function(r){ return r.responseText}"

	viewOptions: 
		drag:true, resize:true, closeOnEscape: true, dataheight: 150

	searchOptions: 
		drag:true, closeAfterSearch: true, multipleSearch:true

	expoptions: 
		excel: 
			caption:"", title: "Export To Excel", buttonicon:"ui-icon-newwin"
		pdf: 
			caption:"", title: "Export To Pdf", buttonicon: "ui-icon-print"
		csv: 
			caption:"", title: "Export To CSV", buttonicon: "ui-icon-document"
		columns:
			caption:"", title: "Visible Columns", buttonicon: "ui-icon-calculator", options:{}

	filterOptions: 
		stringResult: true

	inlineNavOpt= 
		addParams: {} 
		editParams: {}

	setDataType: (value) ->
		@dataType = value
		this
  		
	setGridOptions: (anOptions) ->
		if _.isObject anOptions
			@gridOptions = jQuery.extend true, @gridOptions, anOptions
		this

	getGridOption: (key) ->
		@gridOptions[key]? and @gridOptions[key] or false
		
	setUrl: (newurl) ->
		if !@runSetCommands
			return this
		if newurl.length > 0
			@setGridOptions 
				url: newurl
				editurl: newurl
				cellurl: newurl
		this
	
	setNavOptions: (module, aoptions) ->
		if !@runSetCommands
			return this
		
		switch module
			when 'navigator'
				@navOptions = jQuery.extend true, @navOptions, aoptions
				
			when 'add'
				@addOptions = jQuery.extend true, @addOptions, aoptions

			when 'edit'
				@editOptions = jQuery.extend true, @editOptions, aoptions

			when 'del'
				@delOptions = jQuery.extend true, @delOptions, aoptions

			when 'search'
				@searchOptions = jQuery.extend true, @searchOptions, aoptions

			when 'view'
				@viewOptions = jQuery.extend true, @viewOptions, aoptions
		this

	inlineNavOptions: (module, aoptions) ->
		if !@runSetCommands
			return this
			
		switch module
			when 'navigator'
				@inlineNavOpt = jQuery.extend true, @inlineNavOpt, aoptions
				
			when 'add'
				@inlineNavOpt['addParams'] = jQuery.extend true, @inlineNavOpt['addParams'], aoptions
				
			when 'edit'
				@inlineNavOpt['editParams'] = jQuery.extend true, @inlineNavOpt['editParams'], aoptions
		this


	setColModel: (model=[], params={}, labels={}) ->
		goper = if @oper then @oper else 'nooper' 
		
		console.log 'goper: ', goper
		
		if goper in ['nooper', @gridParams.excel, "pdf", "csv"]
			runme = true 
		else
			runme = goper in _.values @gridParams
		
		console.log 'Run me', runme
		
		if runme
			if !_.isEmpty model
				@colModel = model 
				
				console.log 'Set colModel'
				console.log @colModel
				
				if @primaryKey
					@setColProperty @primaryKey, 
						key: true
				return this
				
		if !runme
			@runSetCommands = false
			
		this
 
	setColProperty: (colname, aproperties={}) ->
		if _.isEmpty aproperties
			return this
		
		if @colModel.length > 0
			if _.isNumber colname
				@colModel[colname] = jQuery.extend true, @colModel[colname], aproperties
			else
				for val, key in @colModel when val.name is colname.trim()
					@colModel[key] = jQuery.extend true, @colModel[key], aproperties
		this

	renderGrid: (tblelement='', pager='', script=true, summary={}, params={}, createtbl=false, createpg=false, echo=true) ->
	
		oper = @gridParams.oper
		
		goper = if @oper then @oper else 'nooper'
		
		console.log 'goper', goper
		
		if goper is @gridParams.autocomplete
			return this
		
		else if goper is @gridParams.excel
			if !@export
				return this
			@exportToExcel summary, params, @colModel, true, @exportfile
			
		else if goper is "pdf"
			if !@export 
				return this
			@exportToPdf summary, params, @colModel, @pdffile

		else if goper is "csv"
			if !@export
				return this
			@exportToCsv summary, params, @colModel, true, @csvfile, @csvsep, @csvsepreplace

		else if goper in _.values(@gridParams)
			if @inlineNav
		 		@getLastInsert = true
		 		
			console.log 'Come here render 1'
			@editGrid summary, params, goper, echo
		  	
		else 
			if !@gridOptions.datatype?
				@gridOptions.datatype = @dataType 
			
			console.log 'Come here render 2'
			
			ed = true
		    	
			if @gridOptions.cmTemplate?
				edt = @gridOptions.cmTemplate
				ed = if edt.editable then edt.editable else true
		
			for cm, k in @colModel
				if @colModel[k].editable?
					@colModel[k].editable = ed
		
			@gridOptions.colModel = @colModel
			
			if @gridOptions.postData?
				@gridOptions.postData[oper] = @gridParams.query
			else
				postData = {}
				postData[oper] = @gridParams.query
				@setGridOptions 
					postData: postData
			
			if @primaryKey?
				@gridParams.id = @primaryKey
		
			@setGridOptions 
				prmNames: @gridParams
				
			if pager.length >0
				#if pager.indexOf "#" is -1
				#	pager = "#" + pager
				if ! "#" in pager
					pager = "#" + pager
				@setGridOptions 
					pager: pager
		
			if @sharedEditOptions
		   		@gridOptions.editOptions = @editOptions
		
			if @sharedAddOptions
				@gridOptions.addOptions = @addOptions
				
			if @sharedDelOptions
				@gridOptions.delOptions = @delOptions
			
			renderObj = {}
			
			renderObj.gridOptions = @gridOptions
			
			if @navigator && pager.length >0
				renderObj.navOptions = @navOptions
				renderObj.editOptions = @editOptions
				renderObj.addOptions = @addOptions
				renderObj.delOptions = @delOptions
				renderObj.searchOptions = @searchOptions
				renderObj.viewOptions = @viewOptions
				
				if @navOptions.excel? && @navOptions.excel
					navExcelButton = {}
					navExcelButton.id = pager.substring(1) + '_excel'
					navExcelButton.caption = @expoptions.excel.caption
					navExcelButton.title = @expoptions.excel.title
					navExcelButton.buttonicon = @expoptions.excel.buttonicon
					renderObj.navExcelButton = navExcelButton
					
			if @toolbarfilter
				renderObj.filterOptions	= @filterOptions
				
			@res.send renderObj

		
exports.JqGridRender = JqGridRender
