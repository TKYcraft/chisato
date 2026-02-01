FROM ruby:3.4.2-slim-bookworm

WORKDIR /opt/app

RUN \
# install apt package.
	apt-get update \
	&& apt-get install -y \
		build-essential \
		libmagickwand-dev\
		libyaml-dev\
		curl \
# clear apt cache.
	&& apt-get clean -y \
	&& rm -rf /var/lib/apt/lists/* \
# add alias
	&& echo "gem: --no-document" >> ~/.gemrc \
	&& echo "alias ll='ls -la'" >> ~/.bashrc

# install rails / bundler
RUN which gem \
	&& gem install rails -v 8.0.0 \
	&& gem install bundler -v 2.5.5 \
	&& rails -v

COPY ./ /opt/app/

RUN bundle install

EXPOSE 3000

ENTRYPOINT ["sh", "entrypoint.sh"]
