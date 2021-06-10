# open manifest.xml and resources.pri.xml and check for missing .png files
cd "‪c:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64\"

.\makepri.exe dump /if 'C:\Users\Ivo\Desktop\New folder\AcrobatProDC_1.0.0.0_x64__0xnp5z67g1ft0\Resources.pri'
code .\Resources.pri.xml