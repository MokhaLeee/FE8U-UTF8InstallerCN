# UTF8InstallerFE8U

Chinese translation patch (via UTF8 encoding) for FE8U.

This project is mainly refering to [FEHRR](https://github.com/laqieer/FEHRR)

## Custom build

1. Install sub-modules

```bash
cd Tools
git clone https://github.com/MokhaLeee/FE-CLib-Mokha.git
git clone https://github.com/StanHash/EventAssembler.git --recursive
git clone https://github.com/StanHash/FE-PyTools.git --recursive
```

2. Install dependence

```bash
sudo apt-get -y install binutils-arm-none-eabi \
    gcc-arm-none-eabi build-essential cmake re2c ghc \
    cabal-install libghc-vector-dev libghc-juicypixels-dev \
    python3-pip pkg-config libpng*

pip install pyelftools PyInstaller tmx six
```

3. Install DevkitPRO

```bash
wget https://apt.devkitpro.org/install-devkitpro-pacman
chmod +x ./install-devkitpro-pacman
./install-devkitpro-pacman
sudo dkp-pacman -S gba-dev
```

3. Build EA

    Get into **Tools/EventAssembler** and then refer to [EA build note](https://github.com/StanHash/EventAssembler).

4. Put **Fire Emblem: The Sacred Stones** clean rom named **fe8.gba** in the repository directory.

4. build:

```bash
make -j
```

## Wizardry note

Since Glyph use such a lot of space, so the custom FreeSpace from `0xB2A610` is not enough. So here we define `FreeFontSpace` as `0xEFB2E0` to install glyphs.

## See also

* [**FE-CBuild**](https://github.com/MokhaLeee/FE-CBuild), a project aims to insert everything through EA in C/Linux/Makefile.
* [**CHAX-Sundry**](https://github.com/MokhaLeee/fe8_hacks_sundries), Mokha C-Hacks collection for FireEmblem8U.
* [**FireEmblemUniverse/fireemblem8u**](https://github.com/FireEmblemUniverse/fireemblem8u), a decompilation of Fire Emblem: The Sacred Stones (US).
