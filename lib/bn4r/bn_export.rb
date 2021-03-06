##############################################################
#
#  Export fuctions of Bayesian Network Library for Ruby
#  
#  Author: Sergio Espeja ( http://www.upf.edu/pdi/iula/sergio.espeja, sergio.espeja at gmail.com )
#  
#  Developed in: IULA ( http://www.iula.upf.es ) and 
#  in bee.com.es ( http://bee.com.es )
#  
#  == Export formats implemented
#  * dot (Graphviz .dot files)  
#  * xbn (Microsoft Belief Networks)
#
##############################################################


#
class BayesNet < DirectedAdjacencyGraph

def to_dot(bn = self)
  #TODO: label relations between nodes
  #TODO: print information about probabilities tables?
  bn.to_dot_graph.to_s
end

def to_xbn(bn = self)
  #TODO beautify code using REXML
  xbn_str = "<?xml version=\"1.0\"?>\n"
  xbn_str += "<ANALYSISNOTEBOOK NAME=\"Notebook.bndefault\" ROOT=\"bndefault\">\n"
  xbn_str += "<BNMODEL NAME=\"bndefault\"><STATICPROPERTIES><FORMAT>MSR DTAS XML</FORMAT>\n"
  xbn_str += "      <VERSION>1.0</VERSION>\n"
  xbn_str += "        <CREATOR>Microsoft Research DTAS</CREATOR>\n"
  xbn_str += "        </STATICPROPERTIES>\n"
  xbn_str += "      <DYNAMICPROPERTIES><PROPERTYTYPE NAME=\"DTASDG_Notes\" TYPE=\"stringarray\"><COMMENT>Notes on the diagram</COMMENT>\n"
  xbn_str += "          </PROPERTYTYPE>\n"
  xbn_str += "        <PROPERTYTYPE NAME=\"MS_Addins\" TYPE=\"stringarray\"/>\n"
  xbn_str += "        </DYNAMICPROPERTIES>\n"

  xbn_str += xbn_variables(bn)
  xbn_str += xbn_structure(bn)
  xbn_str += xbn_distributions(bn)
  
  xbn_str += "  </BNMODEL>\n"
  xbn_str += "</ANALYSISNOTEBOOK>\n"
  
end

private
def xbn_variables(bn = self)
  xbn_str = "<VARIABLES>\n" 
  #<VAR NAME=\"N_intr_le\" TYPE=\"discrete\" XPOS=\"17589\" YPOS=\"6435\">
  # <FULLNAME>n_intr_le</FULLNAME>
  # <STATENAME>Yes</STATENAME>
  # <STATENAME>No</STATENAME>
  #</VAR>
  x_pos_index = Array.new(bn.deep, 0); x0_pos = Array.new(bn.deep, 0)
  num_nodes_in_deep = Array.new(bn.deep, 0)
  
  # get how many nodes are in each deep level to calcule the offset
  bn.vertices.each { |node| num_nodes_in_deep[node.deep-1] += 1 }
  x0_pos = num_nodes_in_deep.collect { |num_nodes| 
    a = num_nodes * 6500
    b = num_nodes_in_deep.max * 6500
    (b-a)/2
  }
  
  bn.nodes_ordered_by_breath_first_search.each { |node|    
    x_pos = x0_pos[node.deep-1] + (6500*x_pos_index[node.deep-1])
    y_pos = 2500 + (5000*(node.deep-1))
    x_pos_index[node.deep-1] += 1;
    xbn_str += "<VAR NAME=\"#{node.name}\" TYPE=\"discrete\" XPOS=\"#{x_pos}\" YPOS=\"#{y_pos}\">\n" 
    xbn_str += "<FULLNAME>#{node.name}</FULLNAME>\n"
    if (node.outcomes - [true,false]).empty?
      xbn_str += "<STATENAME>Yes</STATENAME>\n"
      xbn_str += "<STATENAME>No</STATENAME>\n"
    else
      node.outcomes.each {|o| xbn_str += "<STATENAME>#{o}</STATENAME>\n"}
    end
    xbn_str += "</VAR>\n"
  }
  xbn_str += "</VARIABLES>\n" 
end

def xbn_structure(bn = self)
  xbn_str = "<STRUCTURE>\n"
  bn.nodes_ordered_by_dependencies.each { |node|
    next if node.root? #node.num_parents > 0
    node.parents.each { |parent|
      xbn_str += "<ARC PARENT=\"#{parent.name}\" CHILD=\"#{node.name}\"/>\n"
    }
  }
  #      	<ARC PARENT=\"N_mass_le\" CHILD=\"Count\"/>
  #        <ARC PARENT=\"N_mass_count_le\" CHILD=\"Count\"/>
  #        <ARC PARENT=\"N_intr_le\" CHILD=\"Count\"/>
  #        <ARC PARENT=\"N_mass_le\" CHILD=\"Mass\"/>
  #        <ARC PARENT=\"N_mass_count_le\" CHILD=\"Mass\"/>
  #        <ARC PARENT=\"N_intr_le\" CHILD=\"Mass\"/>
  xbn_str += "</STRUCTURE>\n"
end

def xbn_distributions(bn = self)
 xbn_str = "<DISTRIBUTIONS>\n"
# With parents
#      	<DIST TYPE=\"discrete\">
#      			<CONDSET>
#      				<CONDELEM NAME=\"N_mass_le\"/>
#            	<CONDELEM NAME=\"N_mass_count_le\"/>
#            	<CONDELEM NAME=\"N_intr_le\"/>
#            </CONDSET>
#          	<PRIVATE NAME=\"Count\"/>
#          	<DPIS>
#          		<DPI INDEXES=\"0 0 0 \">0.7 0.3 </DPI>
#	            <DPI INDEXES=\"0 0 1 \">0.3 0.7 </DPI>
#	            <DPI INDEXES=\"0 1 0 \">0.3 0.7 </DPI>
#	            <DPI INDEXES=\"0 1 1 \">0 1 </DPI>
#	            <DPI INDEXES=\"1 0 0 \">1 0 </DPI>
#	            <DPI INDEXES=\"1 0 1 \">0.7 0.3 </DPI>
#	            <DPI INDEXES=\"1 1 0 \">0.7 0.3 </DPI>
#	            <DPI INDEXES=\"1 1 1 \">0.3 0.7 </DPI>
#            </DPIS>
#	    </DIST>
bn.nodes_ordered_by_dependencies.each { |node|
  next if node.root?
  xbn_str += "<DIST TYPE=\"discrete\">\n"
  xbn_str += "  <PRIVATE NAME=\"#{node.name}\"/>\n"
  
  xbn_str += "  <CONDSET>\n"
  node.parents.each { |parent| xbn_str += "    <CONDELEM NAME=\"#{parent.name}\"/>" }
  xbn_str += "  </CONDSET>\n"

  xbn_str += "  <DPIS>\n"

  boolean_combinations = generate_combinations(node.parents)
  boolean_combinations.each { |boolean_combination|
    
    probs = node.outcomes.collect { |n_assignment| 
    p "n_assignment: " + n_assignment.to_s
    node.get_probability(n_assignment, boolean_combination) }
    
    bc_str = boolean_combination.collect {|b| (b)?"0":"1"}.join(" ")
    xbn_str += "  <DPI INDEXES=\"#{bc_str} \">" + probs.join(" ") + " </DPI>\n"
    #<DPI INDEXES=\"0 0 0 \">0.7 0.3 </DPI>
  }
  xbn_str += "  </DPIS>\n"
  xbn_str += "</DIST>\n"
}


# Without parents
#      <DIST TYPE=\"discrete\">
#        	<PRIVATE NAME=\"N_intr_le\"/>
#          <DPIS>
#          	<DPI>0.3 0.7 </DPI>
#          </DPIS>
#        </DIST>
bn.nodes_ordered_by_dependencies.each { |node|
  next unless node.root?
  xbn_str += "<DIST TYPE=\"discrete\">\n"
  xbn_str += "  <PRIVATE NAME=\"#{node.name}\"/>\n"
  xbn_str += "  <DPIS>\n"
  probs = [true, false].collect { |n_assignment| node.get_probability(n_assignment) }
  xbn_str += "  <DPI>" + probs.join(" ") + " </DPI>\n"
  xbn_str += "  </DPIS>\n"
  xbn_str += "</DIST>\n"
}

xbn_str += "</DISTRIBUTIONS>\n"
end

end