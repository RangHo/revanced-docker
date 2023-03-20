# Build CLI application
FROM azul/zulu-openjdk:17-latest as cli-builder

ARG ARG_GITHUB_ACTOR
ARG ARG_GITHUB_TOKEN
ENV GITHUB_ACTOR=${ARG_GITHUB_ACTOR} \
    GITHUB_TOKEN=${ARG_GITHUB_TOKEN}

COPY ./cli /build
WORKDIR /build

RUN ./gradlew build

# Build patches
FROM azul/zulu-openjdk:17-latest as patches-builder

ARG ARG_GITHUB_ACTOR
ARG ARG_GITHUB_TOKEN
ENV GITHUB_ACTOR=${ARG_GITHUB_ACTOR} \
    GITHUB_TOKEN=${ARG_GITHUB_TOKEN}

COPY ./patches /build
WORKDIR /build

RUN ./gradlew build

# Build integrations
FROM cimg/android:2023.02 as integrations-builder

ARG ARG_GITHUB_ACTOR
ARG ARG_GITHUB_TOKEN
ENV GITHUB_ACTOR=${ARG_GITHUB_ACTOR} \
    GITHUB_TOKEN=${ARG_GITHUB_TOKEN}

COPY --chown=circleci:circleci ./integrations /build
WORKDIR /build

RUN ./gradlew assembleDebug

# Build final "executable" image
FROM azul/zulu-openjdk:17-jre-latest

COPY --from=cli-builder /build/build/libs/*-all.jar /cli.jar
COPY --from=patches-builder /build/build/libs/*.jar /patches.jar
COPY --from=integrations-builder /build/app/build/outputs/apk/debug/*.apk /integrations.apk

ENTRYPOINT ["java", "-jar", "/cli.jar", "-b", "/patches.jar", "-m", "/integrations.apk"]
CMD ["--help"]
