# Set a sensible default for path when using Exec resources 
Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

# Import all the node definitions in the nodes folder.
import 'nodes/*.pp'

