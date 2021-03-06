\name{db.open}
\alias{db.open}
\title{Open database connection}
\usage{
  db.open(params)
}
\arguments{
  \item{params}{database connection information}
}
\value{
  connection to database
}
\description{
  Generic function to open a database connection
}
\details{
  Create a connection to a database usign the specified
  parameters. If the paramters contain driver element it
  will be used as the database driver, otherwise it will
  use MySQL.
}
\examples{
\dontrun{
db.open(settings$database)
}
}
\author{
  Rob Kooper
}

