# VeeCAD Files

VeeCAD is an application to design stripboard circuits.
[URL to the VeeCAD site.](https://veecad.com/)

The directories below contain the VeeCAD files for the respective modules:
* Adder
* Amplifier_Inverter
* Diode_Function_Generator
* Integrator (manually switchewd integrator)
* Integrator_V2 (electronically switched integrator)
* Multiplier
* Potentiometer
* Power_Supply

The Tools directory contains the VeeCADNetlist.pl utility to cerate Protel netlist files:

```usage: [perl] VeeCADNetlist.pl <ANF_file> [> <protel_format_file>] [2> <debug_output>]```

VeeCAD is able to process several netlist formats. The default fromat
is Protel. For sake of simplicity this is furtheron referred to as
'VeeCAD netlist'.
Simple netlists can easily be assembled manually.
However, the format is cumbersome as each token is stored on its
own line.
This program converts from a simple but easy-to-read abstraction to the 
VeeCAD format.

## Abstract Netlist Format

Command lines start with a dot '.'.
The token separator is a comma ','.
Any white space is ignored.
Comments start with a '#' and are ignored.

```.PARTS```
  Interprete following lines as parts.
```.NODES```
  Interprete following token lines as circuit nodes.
```designator, outline, value```
  A parts line. Each part consists of a design-name, an outline and a value.
```designator-pin1, designator-pin2, designator-pin3, ...```
  A circuit nodes line.
```.EQU match, replacement```
  Replace a matching full token with a replacement text.
```.MAP match, replacement```
  Replace a matching token pattern with a replacement text.
```.NNN netname|*, number|*```
  Use netname for the next nodes and set the node number.
  '*' for netname: don't care, just set the node number.
  '*' for number:  don't care, just use the netname.
  The default node name is 'N'.
  The node number is auto incremented, starting at 0.
```.COM name```
  Make name a common signal node.
  Any node line containing a this name is supposed to electrically
  belong to the same node. 
  A typical application for this are VCC and GND.

Equivalent replacements (.EQU) are made before mapping (.MAP) replacements.
Only one attempt of an equivalent replacement is made.
Only one attempt of a mapping replacement is made.


