# Omoikane

[Omoikane is the God of Knowledge in the Shinto religion](https://en.wikipedia.org/wiki/Omoikane_(Shinto)). The Omoikane
application is simple Sinatra application designed to run queries against a specific server. All data is browseable
online, and results can be easily exported as CSV.

# Installation

Clone the directory somewhere.

# Configuration

* `SESSION_SECRET`: Run `dd if=/dev/random of=- bs=1024 count=1 | sha256sum` and use the results as your secret;
* `JOBSDIR`: Create a directory in which Omoikane can store all it's application files;
* `PSQL_PATH`: Set to your local `psql` installation, usually `/usr/bin/psql`;
* `RUBYOPT`: Set to `-Ilib`.

# Notifications

If you wish to provide push notifications for your users, open a free account at [Pusher](https://pusher.com/). With
your credentials, create two new environment variables, with the values Pusher will provide you:

* `PUSHER_APP_KEY`
* `NOTIFICATION_PUSHER_URL`

Once those variables are available in the environment, direct your users to the home page of Omoikane, where they
can enable push notifications for themselves. Push notifications are directed to only the person which made the query.
When John submits a job, Jane won't be notified that the job has completed.

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
