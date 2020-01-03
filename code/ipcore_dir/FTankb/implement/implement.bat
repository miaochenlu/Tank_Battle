
 
 
 

 



rem Clean up the results directory
rmdir /S /Q results
mkdir results

rem Synthesize the VHDL Wrapper Files


echo 'Synthesizing example design with XST';
xst -ifn xst.scr
copy FTankb_exdes.ngc .\results\


rem Copy the netlist generated by Coregen
echo 'Copying files from the netlist directory to the results directory'
copy ..\..\FTankb.ngc results\


rem  Copy the constraints files generated by Coregen
echo 'Copying files from constraints directory to results directory'
copy ..\example_design\FTankb_exdes.ucf results\

cd results

echo 'Running ngdbuild'
ngdbuild -p xc7k160t-ffg676-2l FTankb_exdes

echo 'Running map'
map FTankb_exdes -o mapped.ncd  -pr i

echo 'Running par'
par mapped.ncd routed.ncd

echo 'Running trce'
trce -e 10 routed.ncd mapped.pcf -o routed

echo 'Running design through bitgen'
bitgen -w routed -g UnconstrainedPins:Allow

echo 'Running netgen to create gate level Verilog model'
netgen -ofmt verilog -sim -tm FTankb_exdes -pcf mapped.pcf -w -sdf_anno false routed.ncd routed.v
