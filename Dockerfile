ARG GLUE_VERSION

FROM  public.ecr.aws/glue/aws-glue-libs:glue_libs_${GLUE_VERSION}_image_01

LABEL org.opencontainers.image.source="https://github.com/n1ngu/docker-aws-glue-libs"
LABEL org.opencontainers.image.description="Like https://gallery.ecr.aws/glue/aws-glue-libs but better"

# Upgrade to glibc 2.28
# Cherrypick /**/lib*/ and /sbin files from fedora:29 glibc package
# (See `docker run --rm -ti fedora:29 rpm -ql glibc`)
USER root
COPY --from=fedora:29 \
    /lib64/ld-2.28.so \
    /lib64/ld-linux-x86-64.so.2 \
    /lib64/libBrokenLocale-2.28.so \
    /lib64/libBrokenLocale.so.1 \
    /lib64/libSegFault.so \
    /lib64/libanl-2.28.so \
    /lib64/libanl.so.1 \
    /lib64/libc-2.28.so \
    /lib64/libc.so.6 \
    /lib64/libdl-2.28.so \
    /lib64/libdl.so.2 \
    /lib64/libm-2.28.so \
    /lib64/libm.so.6 \
    /lib64/libmvec-2.28.so \
    /lib64/libmvec.so.1 \
    /lib64/libnss_compat-2.28.so \
    /lib64/libnss_compat.so.2 \
    /lib64/libnss_dns-2.28.so \
    /lib64/libnss_dns.so.2 \
    /lib64/libnss_files-2.28.so \
    /lib64/libnss_files.so.2 \
    /lib64/libpthread-2.28.so \
    /lib64/libpthread.so.0 \
    /lib64/libresolv-2.28.so \
    /lib64/libresolv.so.2 \
    /lib64/librt-2.28.so \
    /lib64/librt.so.1 \
    /lib64/libthread_db-1.0.so \
    /lib64/libthread_db.so.1 \
    /lib64/libutil-2.28.so \
    /lib64/libutil.so.1 \
    /lib64/
COPY --from=fedora:29 /sbin/ldconfig /sbin/ldconfig
COPY --from=fedora:29 \
    /usr/lib64/audit \
    /usr/lib64/gconv \
    /usr/lib64/libmemusage.so \
    /usr/lib64/libpcprofile.so \
    /usr/lib64/
COPY --from=fedora:29 /usr/libexec/getconf /usr/libexec/getconf
USER glue_user

# Add Spark XML compatibility
ADD \
    --chown=glue_user:glue \
    https://repo1.maven.org/maven2/com/databricks/spark-xml_2.12/0.12.0/spark-xml_2.12-0.12.0.jar \
    /home/glue_user/aws-glue-libs/jars/

# Fool pypsark legacy setup.py to build dist_info so that
# pip is aware pyspark is actually already installed
WORKDIR /home/glue_user/spark
RUN touch RELEASE && mkdir --parents data licenses examples/src/main/python
WORKDIR /home/glue_user/spark/python
RUN python3 setup.py dist_info

ARG GLUE_VERSION

# Unzip aws-glue-libs and forge dist-info metadata so that
# pip is aware aws-glue-libs is actually already installed
WORKDIR /home/glue_user/aws-glue-libs
RUN mv PyGlue.zip /tmp/aws-glue-libs.zip && unzip /tmp/aws-glue-libs.zip -d PyGlue.zip && rm /tmp/aws-glue-libs.zip
RUN mkdir PyGlue.zip/aws_glue_libs-${GLUE_VERSION}.dist-info
COPY --chown=glue_user:glue <<EOF PyGlue.zip/aws_glue_libs-${GLUE_VERSION}.dist-info/METADATA
Metadata-Version: 2.1
Name: aws-glue-libs
Version: ${GLUE_VERSION}

EOF
WORKDIR /home/glue_user/workspace

ENV DISABLE_SSL=yesss

ENTRYPOINT [ "bash", "-l", "-c", "exec $0 $@"]
CMD ["bash"]
