platforms := 'linux/arm64'
rust_version := 'stable'

default:
    just -l

step0:
    docker buildx build \
        --platform={{ platforms }} \
        -t ink:step0 \
        -f docker/base/step0.Dockerfile \
        .

step1: step0
    docker buildx build \
        --platform={{ platforms }} \
        -t ink:step1-{{ rust_version }} \
        -f docker/base/step1.Dockerfile \
        --build-arg IMG_BASE=ink:step0 \
        --build-arg RUST_VERSION={{ rust_version }} \
        .

step2-clang: step1
    docker buildx build \
        --platform={{ platforms }} \
        -t ink:step2-clang-{{ rust_version }} \
        -f docker/base/step2-clang.Dockerfile \
        --build-arg IMG_BASE=ink:step1-{{ rust_version }} \
        .

target-gnu TARGET: step1
    docker buildx build \
        --platform={{ platforms }} \
        -t ink:{{ rust_version }}-{{ TARGET }} \
        -f docker/target/gnu/{{ TARGET }}.Dockerfile \
        --build-arg IMG_BASE=ink:step1-{{ rust_version }} \
        .

target-clang TARGET: step2-clang
    docker buildx build \
        --platform={{ platforms }} \
        -t ink:{{ rust_version }}-{{ TARGET }} \
        -f docker/target/clang/{{ TARGET }}.Dockerfile \
        --build-arg IMG_BASE=ink:step2-clang-{{ rust_version }} \
        .
