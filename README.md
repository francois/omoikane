# Omoikane

[Omoikane is the God of Knowledge in the Shinto religion](https://en.wikipedia.org/wiki/Omoikane_(Shinto)). The Omoikane
application is a simple Sinatra application designed to run queries against a specific server. All query results are
browseable online, and results can be easily exported as CSV. There exists the concept of a project, where a project
is represented as a series of queries, which can be run multiple times as each query can be parameterized.


# Installation

Clone the directory somewhere, edit the Gemfile and add your preferred database library or libraries:

* `gem "pg"`
* `gem "sqlite"`
* `gem "mysql"`

Once you've added one or more libraries, you must bundle, to calculate the correct dependencies:

    $ bundle install


## Configuration

Create a `.env` file in the project's root directory, with the correct values for your environment:

* `SESSION_SECRET`: Run `dd if=/dev/random of=- bs=1024 count=1 | sha256sum` and use the results as your secret;
* `JOBSDIR`: Create a directory in which Omoikane can store all it's application files;
* `RUBYOPT`: Set to `-Ilib`.
* `OMOIKANE_DATABASE_URL`: The [Sequel](http://sequel.jeremyevans.net/) URL of a database where Omoikane will store it's state.
* `OMOIKANE_TARGET_URL`: The [Sequel](http://sequel.jeremyevans.net/) URL of the database you want to query over Omoikane.

### Notifications

__NOTE__: This part is still in flux. In the original version, it worked, but the latest version does not. We're working on this.

If you wish to provide push notifications for your users, open a free account at [Pusher](https://pusher.com/). With
your credentials, create two new environment variables, with the values Pusher will provide you:

* `PUSHER_APP_KEY`
* `NOTIFICATION_PUSHER_URL`

Once those variables are available in the environment, direct your users to the home page of Omoikane, where they
can enable push notifications for themselves. Push notifications are directed to only the person which made the query.
When John submits a job, Jane won't be notified that the job has completed.


# Running

Start Omoikane's services using [Foreman](https://github.com/ddollar/foreman):

    $ bundle exec foreman start

This will launch two services: the web process as well as a worker process, which runs the actual queries.

You may wish to run Omoikane from [Vagrant](https://www.vagrantup.com/).


# License

Omoikane is released as open source software, under the 3 clause BSD license.

Copyright (c) 2014, François Beausoleil <francois@teksol.info>
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors
may be used to endorse or promote products derived from this software without
specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
