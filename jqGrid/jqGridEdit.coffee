
jqGrid = require './jqGrid'
JqGrid = jqGrid.JqGrid


class JqGridEdit extends JqGrid
	editGrid: (summary= {}, params= {}, oper=false, echo= true) ->
		if !oper
			oper = if @oper then @oper else "grid"

		switch oper
			when 'grid'
				return @queryGrid summary, params, echo
				

exports.JqGridEdit = JqGridEdit
