#!/usr/bin/perl -w
#
# VeeCAD is able to process several netlist formats. The default fromat
# is Protel. For sake of simplicity this is furtheron referred to as
# 'VeeCAD netlist'.
#
# Simple netlists can easily be assembled manually.
# However, the format is cumbersome as each token is stored on its
# own line.
# This program converts from a simple but easy-to-read abstraction to the 
# VeeCAD format.
#
# Abstract Netlist Format
# -----------------------
# Command lines start with a dot '.'.
# The token separator is a comma ','.
# Any white space is ignored.
# Comments start with a '#' and are ignored.
#
# .PARTS
#   Interprete following lines as parts.
# .NODES
#   Interprete following token lines as circuit nodes.
# designator, outline, value
#   A parts line. Each part consists of a design-name, an outline and a value.
# designator-pin1, designator-pin2, designator-pin3, ...
#   A circuit nodes line.
# .EQU match, replacement
#   Replace a matching full token with a replacement text.
# .MAP match, replacement
#   Replace a matching token pattern with a replacement text.
# .NNN netname|*, number|*
#   Use netname for the next nodes and set the node number.
#   '*' for netname: don't care, just set the node number.
#   '*' for number:  don't care, just use the netname.
#   The default node name is 'N'.
#   The node number is auto incremented, starting at 0.
# .COM name
#   Make name a common signal node.
#   Any node line containing a this name is supposed to electrically
#   belong to the same node. 
#   A typical application for this are VCC and GND.
#
# Equivalent replacements (.EQU) are made before mapping (.MAP) replacements.
# Only one attempt of an equivalent replacement is made.
# Only one attempt of a mapping replacement is made.
#
# Input/Output
# ------------
# file      : the input ANF netlist text.
# STDOUT (1): the VeeCAD/Protel formatted netlist text.
# STDERR (2): the parsed input for debugging.
# Use 1> or 2> redirection to file or /dev/null or NUL.
#
use strict;
use warnings;
use diagnostics;

# Input line modes.
my $mode_parts = 1;
my $mode_nodes = 2;
my $mode = 0;

# Ouput lists for parts and nodes.
my @partindex = ();
my @nodeindex = ();
my %nodelist = ();

# Equivalents and mappings.
my %equ = ();
my %map = ();

# Net name and number counters.
my %nnn = ();
# Current net name.
my $net_name = "N";

# Initialize the default net ID counter.
$nnn{$net_name} = 0;

# Common nodes.
my %com = ();

my $lineno = 0;

while (<>) {
  chomp;
  $lineno++;
  my $lineno_f = sprintf("%04d", $lineno);
  
  # Remove redundant white space.
  s/\s+//g;
  
  # Skip or remove comments.
  /^#/ && next;
  s/#.*//g;
  
  # Skip empty lines.
  /^$/ && next;
  
  # Output a part ot node line for debugging.
  if    (/^\./)                { print STDERR "$lineno_f <$_>\n"; }
  elsif ($mode == $mode_parts) { print STDERR "$lineno_f <P:$_>\n"; }
  elsif ($mode == $mode_nodes) { print STDERR "$lineno_f <N:$_>\n"; }
  else                         { die "$lineno_f should not get here."; }
  
  # Handle parts and nodes.
  if    (/^\.PARTS/) { $mode = $mode_parts; next; }
  elsif (/^\.NODES/) { $mode = $mode_nodes; next; }
  
  # Handle equivalent definitions.
  elsif (/^\.EQU([^,]+),(.+)/) {
    print STDERR "     <$1=$2>\n";
    $equ{$1} = $2; 
    next;
  }
  
  # Handle mappings.
  elsif (/^\.MAP([^,]+),(.+)/) {
    print STDERR "     <$1=$2>\n";
    $map{$1} = $2; 
    next;
  }
  
  # Set net name and number.
  elsif (/^\.NNN([^,]+),(.+)/) {
    print STDERR "     <$1=$2>\n";
    unless ($1 eq '*') {
      $net_name = $1;
      unless (exists $nnn{$net_name}) { $nnn{$net_name} = 0; }
    }
    unless ($2 eq '*') {
      $nnn{$net_name} = $2;
    }
    #print STDERR "  ";
    #foreach my $k (keys %nnn) { print STDERR "$k:$nnn{$k} "; }
    #print STDERR "\n";
    next;
  }
  
  # Handle common nodes.
  elsif (/^\.COM([^,]+)/) {
    print STDERR "     <com:$1>\n";
    $com{$1} = 1;
  }
  
  # Ignore unknown commands.
  elsif (/^(\..*)/) { print STDERR "     <ign$1>\n"; next }
  
  # Process a part/node item line.
  my $item = "";
  my $com_node = "";
  
  foreach my $token (split(',', $_)) {
    # Check for common nodes.
    if (exists $com{$token}) {
      $com_node = $token;
      next;
    }
    
    # Replace equivalents.
    if (exists $equ{$token}) {
      print STDERR "     <equ:$token/$equ{$token}>\n";
      $token = $equ{$token};
    }
    
    # Replace mappings.
    foreach my $mapk (keys(%map)) {
      if ($token =~ s/$mapk/$map{$mapk}/) {
        print STDERR "     <map:$mapk/$map{$mapk}>\n";
        last;
      }
    }
    
    $item .= "$token\n";
  }
  
  # Parts are stored directly in the partindex.
  # For nodes, a node-ID is calculated and stored in the nodeindex.
  # The rest of the node is stored in the nodelist at the node-ID.
  if    ($mode == $mode_parts) { push @partindex, $item; }
  elsif ($mode == $mode_nodes) {
    my $net_id = "";
    if ($com_node eq "") {
      my $net_no   = $nnn{$net_name}++;
      my $net_no_f = sprintf("%05d", $net_no); 
      $net_id = $net_name . '_' . $net_no_f;
      push @nodeindex, $net_id; 
    }
    else {
      $net_id = $com_node;
    }
    print STDERR "     <nid:$net_id>\n";
    $nodelist{$net_id} .= $item;
  }
}

# Output parts.
foreach (@partindex) {
  print "[\n$_]\n";
}

# Output nodes.
foreach (@nodeindex, keys %com) {
  print "(\n$_\n$nodelist{$_})\n";
}
