# server functions for Introduction

# widths for logos, 3 per line and 2 per line
logoWidth3 <- 350
logoWidth2 <- 450

output$marine_scotland <- renderImage({
    return (
      list(
        src="images/marinescotland_logo2.jpg",
        contentType="image/jpeg",
        alt="Marine Scotland",
        width=logoWidth3)
      )
  },
  deleteFile=FALSE)

output$emff <- renderImage({
    return (
      list(
        src="images/EMFF_logo.jpg",
        contentType="image/jpeg",
        alt="European Maritime and Fisheries Fund",
        width=logoWidth3)
      )
  },
  deleteFile=FALSE)

output$seascope <- renderImage({
    return (
      list(
        src="images/seascope-logo2.png",
        contentType="image/png",
        alt="SeaScope Fisheries Research",
        width=logoWidth3)
      )
  },
  deleteFile=FALSE)

output$sifids <- renderImage({
    return (
      list(
        src="images/SIFIDS_logo_side.jpg",
        contentType="image/jpeg",
        alt="SIFIDS - Scottish Inshore Fisheries Integrated Data System",
        width=logoWidth2)
      )
  },
  deleteFile=FALSE)

output$st_andrews <- renderImage({
    return (
      list(
        src="images/uni_crest.png",
        contentType="image/png",
        alt="University of St Andrews",
        width=logoWidth2)
      )
  },
  deleteFile=FALSE)


