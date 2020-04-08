# This dockerfile utilizes components licensed by their respective owners/authors.
# Advanced Installer lässt sich im Container installieren und starten.

# ------------
# docker build -f .\AdvancedInstaller.Dockerfile -t advancedinstaller:v16.8 --build-arg ADVINST_VERSION=16.8 --build-arg ADVINST_DOWNLOAD_SHA256=F1F01B1C10B44B3CCC67FF897205D346C3DFB458036F4D61552262AC3AEA32C7 .
# ------------

# Advanced Installer call:
# docker run advancedinstaller:v16.8 'AdvancedInstaller.com' /HELP
# docker run -v C:\local-wokspace:C:\workspace advancedinstaller:v16.8 'AdvancedInstaller.com' /execute C:\workspace\Setup\Setup.aip c:\workspace\Setup\Setup.aip.aic

FROM mcr.microsoft.com/windows/servercore:ltsc2019
ARG ADVINST_VERSION=16.9
ARG ADVINST_DOWNLOAD_SHA256=F1F01B1C10B44B3CCC67FF897205D346C3DFB458036F4D61552262AC3AEA32C7

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV ADVINST_DOWNLOAD_URL https://www.advancedinstaller.com/downloads/${ADVINST_VERSION}/advinst.msi
ENV ADVINST_DIR="C:\\Program Files (x86)\\Caphyon\\Advanced Installer ${ADVINST_VERSION}\\bin\\x86"

LABEL Description="AdvancedInstaller" Vendor="easySoft. GmbH" Version=${ADVINST_VERSION}
# Holt advinst.msi aus den aktuellem Verzeichnis.
# Es könnte aber Sinn machen die Version im Container direkt herunterzuladen. Downloadlink: https://www.advancedinstaller.com/downloads/advinst.msi
# oder direkt mit Version unter https://www.advancedinstaller.com/downloads/16.1/advinst.msi

# steps inspired by "chcolateyInstall.ps1" from "git.install" (https://chocolatey.org/packages/git.install)
RUN Write-Host ('Downloading {0} ...' -f $env:ADVINST_DOWNLOAD_URL); \
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; \
    Invoke-WebRequest -Uri $env:ADVINST_DOWNLOAD_URL -OutFile 'advinst.msi'; \
    \
	Write-Host ('Verifying sha256 ({0}) ...' -f $env:ADVINST_DOWNLOAD_SHA256); \
	if ((Get-FileHash advinst.msi -Algorithm sha256).Hash -ne $env:ADVINST_DOWNLOAD_SHA256) { \
		Write-Host 'FAILED!'; \
		exit 1; \
	}; \
    \
	Write-Host 'Install ...'; \
    Start-Process -Wait -FilePath msiexec.exe -ArgumentList @('/i', 'advinst.msi', '/qn', '/L*V', 'advinst.log'); \
    Remove-Item advinst.msi -Force; \
    $AI_EXE='{0}\\AdvancedInstaller.com' -f $env:ADVINST_DIR; \
    Start-Process -NoNewWindow -Wait -FilePath $AI_EXE -ArgumentList '/HELP'; \
    \
    Write-Host 'Complete.';
WORKDIR $ADVINST_DIR
