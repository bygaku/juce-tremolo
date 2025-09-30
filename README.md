# Template for JUCE.
A minimal JUCE plug-in template with CMake.


## 🚩 flow
```bash
# clone from template repository and init submodule
git clone --recurse-submodules https://github.com/bygaku/juce-template.git

# move to the directory
cd ./juce-template

# execution setup.ps1
.\bin\setup.ps1 -ProjectName "SuperDelay" -CompanyName "My Audio Labs"

# normal build
.\bin\build.ps1

# build with Run option.
.\bin\build.ps1 -Run
```


## ⚙️ way to setup
```bash
# minimal specification.
.\bin\setup.ps1 -ProjectName "SuperDelay"

# specify company name.
.\bin\setup.ps1 -ProjectName "SuperDelay" -CompanyName "My Audio Labs"

# another specify pattern.
.\bin\setup.ps1 -P "SuperDelay" -C "My Audio Labs"
```

## 💡 if you wanna see help
```bash
# setup.ps1 shows help.
.\bin\setup.ps1 -Help

# build.ps1 shows help.
.\bin\build.ps1 -Help
```
