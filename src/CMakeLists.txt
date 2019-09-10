# Contributed by BobOng, 2019/08/12

project(World)

aux_source_directory(./ DIR_SRCS)

include_directories(./)
add_library(World STATIC ${DIR_SRCS})

file(COPY "./world" DESTINATION "${INCLUDE_EXPORT_DIRECTORY}")
