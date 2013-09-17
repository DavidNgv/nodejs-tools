utils = require './../utils'
Utils = utils.Utils

_ = require 'underscore'
jQuery = require 'jquery'

async = require 'async'


class JqGrid
	constructor: (@req, @res, @dbProvider= null, @dbtype= 'mongodb') ->
		@oper = Utils.getParam @req, @gridParams.oper, false
	
	dataType: 'xml'
	
	encoding: 'utf-8'
	
	jsonencode: true
	datearray: {}
	
	mongointegers: {}
	mongofields: {}
	
	selectCommand: ''
	
	exportCommand: ''
	gSQLMaxRows: 1000
	subgridCommand: ''
	table: ''
	
	primaryKey: null
	
	readFromXML: false
	userdata: null
	customFunc: null
	customClass: false
	customError: null
	xmlCDATA: false
	optimizeSearch: false
	cacheCount: false
	performcount: true
	oper: null
 	
	gridParams:
		page: "page", rows: "rows", sort: "sidx", order: "sord", search: "_search",  nd: "nd", id : "id", filter: "filters",  searchField: "searchField", searchOper: "searchOper", searchString: "searchString", oper: "oper", query: "grid", addoper: "add",   editoper: "edit", deloper: "del", excel: "excel", subgrid: "subgrid", totalrows: "totalrows", autocomplete: "autocmpl"
	
	mongoexecute: (collection, query, sql, limit, nrows, offset, order, sort, fields, cb) ->
		query ?= {}
		fields ?= {}
		
		if collection
			sql = collection.find query, fields
			if order
				if sort is 'desc'
					sort = -1
				else
					sort = 1 
				sql = sql.sort [[order, sort]]
				
			if limit && nrows >= 0
				sql = sql.limit(nrows).skip(offset)
				
			if sql 
				cb null, sql
			else
				cb 'Error', null
		return
		
	execute: (sqlId, params, limit=false,nrows=-1,offset=-1, order='', sort='', cb) ->
		if @dbtype is 'mongodb'
			@mongoexecute sqlId, params, sql, limit, nrows=0, offset, order, sort, @mongofields, (err, sql) =>
				cb err, sql
			
	
	_mongoSearch: (mongoquery) ->
		s = ''
		v= {}
		
		sopt = {'eq' : '===','ne' : '!==','lt' : '<','le' : '<=','gt' : '>','ge' : '>=','bw':"",'bn':"",'in':'==','ni': '!=','ew':'','en':'','cn':'','nc':''}
		
		filters = Utils.getParam @req, @gridParams.filter, ""
		
		rules = []
		
		if filters
			jsona = JSON.parse filters
			
			console.log 'filters'
			console.log jsona
			
			gopr = jsona['groupOp'].trim().toLowerCase()
			rules = jsona['rules']
			
		else if Utils.getParam @req, @gridParams.searchField, ''
			gopr = 'or'
			rules[0]['field'] = Utils.getParam @req, @gridParams.searchField, ''
			rules[0]['op'] = Utils.getParam @req, @gridParams.searchOper, ''
			rules[0]['data'] = Utils.getParam @req, @gridParams.searchString, ''
		
		if gopr is 'or' 
			gopr = ' || '
		else 
			gopr = ' && '
		i = 0
		
		mongoquery ?= {}
		
		for val, key in rules
			field = val['field']
			
			op = val['op']
			v = val['data']
			
			if v.length isnt 0 && op
				isString = true
				
				#if in_array(field,datearray)
					#av = explode(",",JqGridUtils.parseDate('d/m/Y H:i:s',v,'Y,m,d,H,i,s'))
					
					#av[1] = (int)av[1]-1
					
					#v = "new Date(".implode(",",av).")"
					
				#	isString = false
				
				#if in_array(field,mongointegers)
				#	isString = false; 
				
				i++
				
				if i > 1
					s += gopr
				
				switch op  
					when 'bw'  
						s += "this." + field + ".match(/^#{v}.*/i)"; 
					when 'bn'
						s += "!this." + field + ".match(/^#{v}.*/i)"; 
					when 'ew'
						s += "this." + field + ".match(/^.*#{v}/i)"; 
					when 'en'
						s += "!this." + field + ".match(/^.*#{v}/i)"; 
					when 'cn'
						s += "this." + field + ".match(/^.*#{v}.*/i)"; 
					when 'nc'
						s += "!this." + field + ".match(/^.*#{v}.*/i)"; 
					else
						if isString
							v = "'" + v + "'"; 
						s += " this." + field + " " + sopt[op] + v
		
		
		mongoquery = jQuery.extend true, mongoquery, 
			'$where': "function(){ return " + s + ";}"
		
		return mongoquery
	
	_mongocount: (collection, query, sumcols, callback) ->
		qryRecs = {}
		
		qryRecs['COUNT'] = 0
		
		query ?= {}
		
		v = collection.count query, (err, count) ->
			if count? && count>=0
				qryRecs['COUNT'] = count
			callback err, qryRecs
		
		###
		keys = {}
		
		initial = {"COUNT": 0}
		
		s = ''
		
		if !_.isEmpty(sumcols)
			for k, v of sumcols
				initial[k] = 0
				s += " prev['" + k + "'] += obj." + v + "; "
				
			reduce = "function (obj, prev) { prev.COUNT++;" + s + "}"
		
			res = collection.group keys, initial, reduce, {"condition": query}
		
			return res['retval'][0]
		###
		
	_sqlSearch: (sqlquery) ->
		s = ''
		v= {}
		
		sopt = {'eq' : '===','ne' : '!==','lt' : '<','le' : '<=','gt' : '>','ge' : '>=','bw':"",'bn':"",'in':'==','ni': '!=','ew':'','en':'','cn':'','nc':''}
		
		filters = Utils.getParam @req, @gridParams.filter, ""
		
		rules = []
		
		if filters
			jsona = JSON.parse filters
			
			console.log 'filters'
			console.log jsona
			
			gopr = jsona['groupOp'].trim().toLowerCase()
			rules = jsona['rules']
			
		else if Utils.getParam @req, @gridParams.searchField, ''
			gopr = 'or'
			rules[0]['field'] = Utils.getParam @req, @gridParams.searchField, ''
			rules[0]['op'] = Utils.getParam @req, @gridParams.searchOper, ''
			rules[0]['data'] = Utils.getParam @req, @gridParams.searchString, ''
		
		if gopr is 'or' 
			gopr = ' || '
		else 
			gopr = ' && '
		i = 0
		
		sqlquery ?= {}
		
		for val, key in rules
			field = val['field']
			
			op = val['op']
			v = val['data']
			
			if v.length isnt 0 && op
				isString = true
				
				i++
				
				if i > 1
					s += gopr
				
				switch op  
					when 'bw'  
						s += field + " LIKE '#{v}%'"; 
					when 'bn'
						s += "! " + field + "LIKE '#{v}%'"; 
					when 'ew'
						s += field + " LIKE '%#{v}'"; 
					when 'en'
						s += "! " + field + " LIKE '%#{v}'"; 
					when 'cn'
						s += field + " LIKE '%#{v}%'"; 
					when 'nc'
						s += "! " + field + " LIKE '%#{v}%'"; 
					else
						if isString
							v = "'" + v + "'"; 
						s += field + " " + sopt[op] + v
		
		
		sqlquery = jQuery.extend true, sqlquery, 
			'where': s
		
		return sqlquery
		
	queryGrid: ( summary={}, params={}, echo=true) ->
		page = @gridParams['page'] 
		page = parseInt Utils.getParam(@req,page,'1') 
		
		limit = @gridParams['rows'] 
		limit = parseInt Utils.getParam(@req,limit,'20') 
		
		sidx = @gridParams['sort'] 
		sidx = Utils.getParam(@req,sidx,'') 
		
		sord = @gridParams['order'] 
		sord = Utils.getParam(@req,sord,'') 
		
		search = @gridParams['search'] 
		search = Utils.getParam(@req,search,'false') 
		
		totalrows = Utils.getParam(@req,@gridParams['totalrows'],'') 
		
		sord = sord.replace /[^a-zA-Z0-9]/, ""
		sidx = sidx.replace /[^a-zA-Z0-9. _,]/, ""
		
		console.log 'Come here queryGrid'
		
		performcount = true 
		gridcnt = false 
		gridsrearch = '1' 
		
		if @cacheCount
			gridcnt = Utils.getParam(@req,'grid_recs',false) 
			gridsrearch = Utils.getParam(@req,'grid_search','1') 
			if gridcnt && parseInt(gridcnt) >= 0
				performcount = false 
		
		if search is 'true'
			if @dbtype is 'mongodb'
				params = @_mongoSearch params
			else if @dbtype is 'mysql'
				params = @_sqlSearch params
		else 
			if @cacheCount && gridsrearch isnt "-1"
				if gridsrearch isnt '1'
					performcount = true 
		
		console.log 'Search query:'
		console.log params
		
		performcount = performcount && @performcount 
		
		count = 0
		result = {}
		
		fields = for col in @colModel
			col.name
		
		if @dbtype is 'mongodb'	
			async.waterfall [
				(cb) =>
					@dbProvider.queryCursorCount @req.params.collection, params, fields, (error, cursor, return_count) ->
						if performcount
							cb error, cursor, return_count
						else 
							#count = gridcnt 
							cb error, cursor, gridcnt
						###
						@_mongocount sqlId, params, summary, (err, qryData) =>
							if !qryData['count']?
								qryData['count'] = null
				
							if !qryData['COUNT']?
								qryData['COUNT'] = null
							count = if qryData['COUNT'] then qryData['COUNT'] else if qryData['count'] then qryData['count'] else 0
						
							delete qryData['COUNT']
							delete qryData['count']
		
							for k, v of qryData
								if v is null
									v = 0 
								result.userdata[k] = v 
		
							cb err, count
						###
					
				(cursor, return_count, cb) =>
					count = return_count
					if count > 0 
						total_pages = Math.ceil(count/limit) 
					else 
						count = 0 
						total_pages = 0 
						page = 0 

					 
					if page > total_pages 
						page=total_pages 
		
					start = limit*page - limit 
					if start<0
						start = 0 
		
					if @cacheCount
						result.userdata['grid_recs'] = count 
						result.userdata['grid_search'] = gridsrearch 
						result.userdata['outres'] = performcount 
		
					if @userdata
						if result.userdata? 
							result.userdata = {}
						result.userdata = _.extend(result.userdata, @userdata) 
		
					result.records = count 
					result.page = page 
					result.total = total_pages 
		
					uselimit = true 
		
					if totalrows 
						totalrows = parInt(totalrows)
			
						if totalrows is -1
							uselimit = false 
				
						else if totalrows >0
							limit = totalrows 
		
					if uselimit 
						cursor.skip(start).limit(parseInt(limit))
				
					if sidx && sord
						cursor.sort([ [sidx, sord] ])
				
					cursor.toArray (err, docs) =>
						cb err, docs
					#@execute cursor, params, uselimit, limit, start, sidx, sord, (err, sql) =>
					#	cb err, sql
			], (err, docs) =>
				if err
					Utils.handleError 'Cound not query', err, @res
				else
					schema_map = for col in @colModel
						col.name
				
					console.log 'schema_map:'
					console.log schema_map
				
					result.rows = []
				
					for doc in docs
						aRow = id: doc._id, cell: []
			
						for prop in schema_map
							aRow.cell.push doc[prop]
			
						result.rows.push aRow
		
					Utils.handleResponse 'Success query grid', result, @res
					
		else if @dbtype is 'mysql'	
			async.waterfall [
				(cb) =>
					@dbProvider.count().complete (err, return_count) ->
						if performcount
							cb err, return_count
						else 
							#count = gridcnt 
							cb err, gridcnt
							
				(return_count, cb) =>
					count = return_count
					if count > 0 
						total_pages = Math.ceil(count/limit) 
					else 
						count = 0 
						total_pages = 0 
						page = 0 

					 
					if page > total_pages 
						page=total_pages 
		
					start = limit*page - limit 
					if start<0
						start = 0 
		
					if @cacheCount
						result.userdata['grid_recs'] = count 
						result.userdata['grid_search'] = gridsrearch 
						result.userdata['outres'] = performcount 
		
					if @userdata
						if result.userdata? 
							result.userdata = {}
						result.userdata = _.extend(result.userdata, @userdata) 
		
					result.records = count 
					result.page = page 
					result.total = total_pages 
		
					uselimit = true 
		
					if totalrows 
						totalrows = parInt(totalrows)
			
						if totalrows is -1
							uselimit = false 
				
						else if totalrows >0
							limit = totalrows 
					
					findOptions = {offset: start, limit: parseInt(limit), order: sidx + ' ' + sord}
					
					findOptions = jQuery.extend true, findOptions, params
					
					if @dbProvider.includeClass?
						#console.log 'includeClass'
						#console.log @dbProvider.includeClass()
						
						findOptions.include = @dbProvider.includeClass()
		
					if uselimit 
						@dbProvider.findAll(findOptions).complete (err, docs) ->
							cb err, docs
			
			], (err, docs) =>
				if err
					Utils.handleError 'Cound not query', err, @res
				else
					#console.log 'docs:'
					#console.log docs
					
					schema_map = for col in @colModel
						col.name
				
					console.log 'schema_map:'
					console.log schema_map
				
					result.rows = []
				
					for doc in docs
						aRow = id: doc.id, cell: []
			
						for prop in schema_map
							subProps = prop.split '.'
							if subProps.length > 1
								#console.log 'subProps:', subProps
								subDoc = doc
								for subProp in subProps
									subDoc = subDoc[subProp]
								aRow.cell.push subDoc	
							else
								aRow.cell.push doc[prop]
			
						result.rows.push aRow
		
					Utils.handleResponse 'Success query grid', result, @res
					


exports.JqGrid = JqGrid
