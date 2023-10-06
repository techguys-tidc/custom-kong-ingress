FROM --platform=linux/amd64 kong:3.4

# Define environment variables for plugin versions
ENV OIDC_PLUGIN_VERSION=1.4.0-1
ENV JWT_PLUGIN_VERSION=1.1.0-1

# Install necessary dependencies as root
USER root
RUN apt-get update && \
    apt-get install -y git unzip luarocks

# Install the OIDC plugin
RUN luarocks install kong-oidc

# Clone and install the OIDC plugin from source
RUN git clone --branch v${OIDC_PLUGIN_VERSION} https://github.com/revomatico/kong-oidc.git
WORKDIR /kong-oidc
RUN mv kong-oidc.rockspec kong-oidc-${OIDC_PLUGIN_VERSION}.rockspec
RUN luarocks make

# Pack and install the OIDC plugin with a specific version
RUN luarocks pack kong-oidc ${OIDC_PLUGIN_VERSION} \
    && luarocks install kong-oidc-${OIDC_PLUGIN_VERSION}.all.rock

# Clone and install the JWT Keycloak plugin from source
WORKDIR /
RUN git clone --branch 20200505-access-token-processing https://github.com/BGaunitz/kong-plugin-jwt-keycloak.git
WORKDIR /kong-plugin-jwt-keycloak
RUN luarocks make

# Pack and install the JWT Keycloak plugin with a specific version
RUN luarocks pack kong-plugin-jwt-keycloak ${JWT_PLUGIN_VERSION} \
    && luarocks install kong-plugin-jwt-keycloak-${JWT_PLUGIN_VERSION}.all.rock

RUN installed_versions=$(luarocks list --porcelain lua-resty-session) \
    && num_installed_versions=$(echo "$installed_versions" | wc -l) \
    && if [ "$num_installed_versions" -gt 1 ]; then \
    version_to_remove=$(echo "$installed_versions" | head -n 1); \
    echo "Removing $version_to_remove..."; \
    luarocks remove $(echo "$version_to_remove"| awk '{print $1 " " $2}') --force; \
fi

USER kong