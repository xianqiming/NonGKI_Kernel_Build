# Non-GKI Kernel with KSU and SUSFS
![GitHub branch check runs](https://img.shields.io/github/check-runs/JackA1ltman/NonGKI_Kernel_Build/main)![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/JackA1ltman/NonGKI_Kernel_Build/latest/total)  
[支持列表](Supported_Devices.md) | 中文文档 | [English](README_EN.md) | [更新日志](Updated.md)  

**Ver**.1.4

**Non-GKI**：我们常说的Non-GKI包括了GKI1.0（内核版本4.19-5.4）（5.4为QGKI）和真正Non-GKI（内核版本≤4.14）  

由于Non-GKI内核存在严重的碎片化，不仅仅体现在内核无法通用，更是存在编译环境参差不齐，包括但不限于系统版本，GCC版本，Clang版本等等，因此决定开始自动化编译Non-GKI内核项目  
本项目欢迎Fork后自行编辑使用，也欢迎增加修改后提交合并，或者成为合作伙伴  

**切换其他KernelSU分支**：仅需要在当前设备下安装新KernelSU分支的APK安装包后，刷入修改过分支的内核，即可实现无缝切换KernelSU分支  

# 使用例
## Profiles/设备代号_ROM名称.env
总共由以下内容组成：  
**CONFIG_ENV** - 用来表明在Action环境中具体配置文件位置  

**DEVICE_NAME** - 设备全称，格式：设备品牌_型号_地区  
**DEVICE_CODENAME** - 设备代号  

**CUSTOM_CMDS** - 通常用于指明所用编译器/备用编译器  
**EXTRA_CMDS** - 通常用于编译器所需的自定义参数  

**KERNEL_SOURCE** - 内核源码所在之处  
**KERNEL_BRANCH** - 内核源码所需分支  

**CLANG_SOURCE** - Clang所在之处，但支持git、tar.gz、tar.xz  
**CLANG_BRANCH** - Clang所需分支，但前提是git  

**GCC_GNU** - 若你的内核需要GCC，但不需要自定义GCC，可通过选项启用系统提供的GNU-GCC，true或false  
**GCC_XX_SOURCE** - GCC所在之处，但支持git、tar.gz、zip  
**GCC_XX_BRANCH** - GCC所需分支，但前提是git  

**DEFCONFIG_SOURCE** - 若有自定义DEFCONFIG文件需求可提供DEFCONFIG文件的下载地址  
**DEFCONFIG_NAME** - 不管是否自定义，都需要提供用于编译的必要DEFCONFIG文件，通常格式为：设备_defconfig、vendor/设备_defconfig  
**DEFCONFIG_ORIGIN_IMAGE** - (实验性⚠)若你不需要内核源码中自带的DEFCONFIG，也无法提供自定义DEFCONFIG，则可以通过你所获取到的Image文件（Image.gz和Image.gz-dtb需要自行解压后上传文件）进行解包后获得defconfig文件，**DEFCONFIG_NAME**一定要填写，这不能为空

**KERNELSU_SOURCE** - 你可以自行设定KernelSU的来源，通常情况下是setup.sh。但有需求可启用手动安装的方式，此时则为git  
**KERNELSU_BRANCH** - 提供KernelSU的所属分支  
**KERNELSU_NAME** - 部分KernelSU分支存在不同的名称，所以你需要填写正确名称，默认为KernelSU  

**SUSFS_ENABLE** - 是否在编译时启用SUSFS，true或false  
**SUSFS_FIXED** - 是否启用SUSFS错误修补，一般用于内核修补时产生错误后，二次补充修补  

**AK3_SOURCE** - Anykernel3所在之处，若需要的话，仅支持git  
**AK3_BRANCH** - Anykernel3所需分支  

**BOOT_SOURCE** - 若你已经启用MKBOOTIMG的方式，要填写原始干净内核的地址，仅限img格式  

**LXC_ENABLE** - (实验性⚠)启用自动化内核LXC/Docker支持，true或false  

**HAVE_NO_DTBO** - (实验性⚠)若你的内核没有提供dtbo.img，且你的设备属于A/B分区且存在dtbo分区，则可启用本选项(true)，默认为false  
**HAVE_NO_DTBO_TOOL** - (实验性⚠)在上一项启用后，你可以选择启用这项来获得更加安全的生成dtbo.img方案  

**ROM_TEXT** - 用于编译成功后用于上传文件标题，声明内核可用的ROM  

## .github/workflow/build_kernel_设备简称_型号_ROM_Android版本.yml
我们编写了env和用于编译的yml的例本，接下来是对yml例本的解析  
这里仅指出大概可供修改的地方，具体可按需求修改，我们不建议过度修改步骤和顺序  
本项目提供的所有补丁均不能保证在≤4.4内核能够正常使用  
这是我们提供的示例文件：**codename_rom_template.env**和**build_kernel_template.yml**  
**build_kernel_arch_template.yml**为基于Arch Linux的示例YAML，当前为Beta测试  

- **env:** - 设置必要修改的变量，独立于Profiles
  - **PYTHON_VERSION** - Ubuntu的Python命令默认为Python3，但2仍有需求，因此增加该变量，可填写**2**或**3**。如果你仅仅需要安装python2但不想修改默认python，那你可以在EXTRA_CMDS中增加PYTHON=/usr/bin/python2，便可以强制执行python2参与编译
  - **PACK_METHOD** - 打包方式，分为MKBOOTIMG，和[Anykernel3](https://github.com/osm0sis/AnyKernel3)，默认为Anykernel3
  - **KERNELSU_METHOD** - 嵌入KernelSU的方式：
    - 通常情况下使用**shell**方式即可
    - 但如果你提供了非setup.sh的方式，或者该方式报错，请将其修改**manual**，manual虽然是手动安装，但实际上并不需要维护者修改任何内容，但注意，选该模式仅能使用git
    - 若你的内核已经存在KernelSU，但你想要替换，可使用**only**，仅执行git不执行修补
  - **PATCHES_SOURCE** - 使用susfs不可避免需要手动修补，这是用来填写你存放patch的github项目地址，当然如果你不采用susfs，则不需要填写，可参考我的用于Patch的git项目
  - **PATCHES_BRANCH** - patch项目所需的分支，一般为main
  - **HOOK_METHOD** - 我们提供了两种方式用于KernelSU手动修补：
    - **normal**代表最常见的修补方式，一般不会出问题
    - [vfs](https://github.com/backslashxx/KernelSU/issues/5)是最新的最小化修补方式，似乎会提高隐藏，但是在低版本clang下可能会有ISO编译规范问题，且对于版本≤4.9的内核的支持存在问题，仅更高版本内核建议启用
  - **PROFILE_NAME** - 填写成你修改好的env环境变量文件的名称，例如codename_rom_template.env
  - **KERNELSU_SUS_PATCH** - 如果你的KernelSU不属于KernelSU-Next，并且也没有针对SuSFS的修补分支，可以启用该项目（true），但我们不建议这么做，因为分支KernelSU的魔改情况严重，手动修补已经不能顺应现在的时代了
  - **KPM_ENABLE** - (实验性⚠)启用对SukiSU-Ultra的KPM编译支持，该项为实验项，请小心启用
  - **KPM_PATCH_SOURCE** - (实验性⚠)你需要自行提供patch二进制文件的下载链接
  - **GENERATE_DTB** - 如果你的内核编译后，需要DTB文件（不是.dtb、.dts、.dtsi），则可以开启本项自动执行生成DTB步骤
  - **GENERATE_CHIP** - 生成DTB文件的对应设备CPU，通常支持qcom、mediatek，但我们不确定其他CPU是否支持
  - **BUILD_DEBUGGER** - 若需要提供出错时的报告可使用该选项，目前提供patch错误rej文件的输出，其他功能可期待未来更新
  - **BUILD_OTHER_CONFIG** - 若你需要合并内核源码中自带的其他.config文件，可启用本项，但是需要自行修改”Build Kernel“中数组MERGE_CONFIG_FILES中的内容

- **runs-on: ubuntu-XX.XX** 
  - 不同内核所需系统不同，默认为22.04，我们预先提供了两套包安装选项（适配22.04和24.04），我们通过检测系统版本进行决定包安装
  - 若使用Arch Linux YAML则该功能不适用，请不要修改

- **Set Compile Environment**
  - 这里分为无GCC和有GCC，Clang也有区分判定，请继续往下看
  - 若无GCC，则会自动选择仅Clang，而通常情况下，仅Clang可用于使用antman进行管理的Clang，这些步骤我们都已经可以自动识别，因此不需要修改yml来实现
  - 若有GCC，则需填写GCC 64位和32位的版本，对于GCC我们建议git形式，但同时支持tar.gz和zip
  - 你可以选择仅使用GCC而不启用Clang，并且GCC允许使用系统默认安装的GCC，可在yaml文件变量中开启
  - 根据本人的使用情况，我们对于Clang支持为git、tar.gz、tar.xz、zip以及上述提到的antman管理软件
  - 如果你计划使用[Proton Clang 13](https://github.com/kdrag0n/proton-clang)，则需要在将系统设置为**Ubuntu-20.04**（我们不推荐Arch Linux，可能会导致glibc问题），我们已经预先适配了Proton Clang Toolchain，会在检测到Proton Clang后自动识别附带的GCC，但也记得不要填写GCC

- **Get Kernel Source**
  - 正常来说内核源码都可以通过Git方式获得，所以基本不需要修改
  - 某些国产厂商的水平堪忧，开源但却是自打包，或者驱动与内核源码分离，因此可能需要你自己修改这个部分
  
- **Set Pack Method and KernelSU and SUSFS**
  - 我们默认提供Anykernel3和MKBOOTIMG两种打包方式，其中AK3可以自动检测内核源码中是否存在，若不存在则调用env提供的SOURCE和BRANCH，对于AK3仅提供git方式，MKBOOTIMG由我们默认提供，一般不需要自行获取
  - **Anykernel3** 需要提供对应项目的地址和分支，且仅支持git方式，或者使用我们提供的默认方式，一般不会出错
  - **MKBOOTIMG** 需要提供干净的原始内核镜像文件，我们建议使用Github raw地址

- **Extra Kernel Options** 
  - 有些内核编译时需要提供更多设置项
  - 通常为针对defconfig文件的补充项，但的确，有些完善的内核其实并不需要额外的设置项，不需要就把该模块中所有内容注释掉即可跳过

- **Added mkdtboimg to kernel (Experiment)** 
  - 如你所见，很多内核，或者说大部分内核都不需要该功能，有些内核例如nameless虽然没有dtbo,但实际上他的确不需要。而且仅限A/B分区的设备，且存在危险性，例如加上dtbo反而无法启动设备等等，三思而后行

- **Setup LXC (Experiment)** 
  - 自动部署LXC，但许多内核并不支持该方式，可用于Fork后自行尝试，在本人的官方编译中应该不会选择支持LXC
  
- **Patch Kernel**
  - 分为两个部分，主要的SUSFS修补和补充修补（Patch Kernel of SUSFS 和 Fixed Kernel Patch）
  - 一切基于env中SUSFS_ENABLE和env.SUSFS_FIXED为true，但不一定都为true
  - SUSFS修补大概率会产生问题，因此通常情况下需要补充修补
  - 补充修补需要执行你重新制作的patch补丁（步骤为：Fixed Kernel Patch）
  
- **KPM Patcher (Experiment)**
  - 为SukiSU-Ultra提供KPM内核Patch功能，该功能目前暂不支持内核版本≤4.9的设备，若你已经反向移植部分功能用于KPM功能，请自行参照修改这个部分，但我们对实验性功能不提供支持
  
最后提醒⚠️：非上述提示的步骤理论上不需要你做任何修改，我已经尽可能实现多情况判定
