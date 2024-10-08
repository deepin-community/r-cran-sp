# Copyright (c) 2003-23 by Barry Rowlingson and Roger Bivand

if (!is.R()) {
  strsplit <- function(a,b) {
    if (a == as.character(NA))
        return(as.character(NA))
    else list(unlist(unpaste(a, b)))
  }
}

if (!isGeneric("rebuild_CRS"))
	setGeneric("rebuild_CRS", function(obj)
		standardGeneric("rebuild_CRS"))

setMethod("rebuild_CRS", signature(obj = "CRS"),
	function(obj) {
            if (is.null(comment(obj))) {
                obj <- CRS(slot(obj, "projargs"))
            } 
            obj
        }
)


"CRS" <- function(projargs=NA_character_, doCheckCRSArgs=TRUE,
    SRS_string=NULL, get_source_if_boundcrs=TRUE, use_cache=TRUE) {
# cautious change BDR 150424
# trap NULL too 200225
    if (is.null(projargs))
        warning("CRS: projargs should not be NULL; set to NA")
    if ((is.null(projargs)) || (!is.na(projargs) && !nzchar(projargs))) projargs <- NA_character_
# condition added 140301
    stopifnot(is.logical(doCheckCRSArgs))
    stopifnot(length(doCheckCRSArgs) == 1L)
    stopifnot(is.logical(get_source_if_boundcrs))
    stopifnot(length(get_source_if_boundcrs) == 1L)
    stopifnot(is.character(projargs))
#    CRS_CACHE <- get("CRS_CACHE", envir=.sp_CRS_cache)
    input_projargs <- projargs
    if (is.na(projargs)) { # fast track for trivial CRS()
        if (is.null(SRS_string))
            return(new("CRS", projargs = NA_character_))
    } else if (use_cache) {
        res <- .sp_CRS_cache[[input_projargs]]
        if (!is.null(res)) {
            return(res)
        }
    }
    if (requireNamespace("sf", quietly = TRUE)) {
            if ((length(grep("^[ ]*\\+", projargs)) > 0L) &&
                !is.null(SRS_string)) projargs <- NA_character_
            if ((is.na(projargs) && !is.null(SRS_string))) {
                res <- sf::st_crs(SRS_string)
                res <- as(res, "CRS")
            } else {
                res <- sf::st_crs(projargs)
                res1 <- try(as(res, "CRS"), silent=TRUE)
                if (inherits(res1, "try-error")) {
                    res <- new("CRS", projargs=projargs)
                    warning("invalid PROJ4 string")
# rbgm workaround for +proj=utm +zone=18 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs +# +a=6378137.0 +es=0.006694380022900787 +lon_0=-75d00 +lat_0=0d00 +x_0=500000.0 +y_0=0.0 +k=0.9996 in bgmfiles Final_CAM_Boxes_8.bgm
                } else {
                    res <- res1
                }
            }
            if (!is.na(slot(res, "projargs")))
                .sp_CRS_cache[[input_projargs]] <- res
            return(res)
    } else {
            if (get("startup_message", envir=.spOptions) != "none")
                warning("sf required")
    }
    if (!is.na(projargs)) {
        if (length(grep("latlon", projargs)) != 0)
            stop("northings must follow eastings: ", projargs)
        if (length(grep("lonlat", projargs)) != 0) {
            projargs <- sub("lon", "long", projargs)
            warning("'lonlat' changed to 'longlat': ", projargs)
        }
    }    
    if (is.na(projargs)) {
        uprojargs <- projargs
    } else {
        uprojargs <- paste(unique(unlist(strsplit(projargs, " "))), 
	collapse=" ")
        if (length(grep("= ", uprojargs)) != 0)
	    stop(paste("No spaces permitted in PROJ4 argument-value pairs:", 
	        uprojargs))
        if (length(grep(" [:alnum:]", uprojargs)) != 0)
	    stop(paste("PROJ4 argument-value pairs must begin with +:", 
	        uprojargs))
    }
    comm <- NULL
    res <- new("CRS", projargs=uprojargs)
    if (!is.null(comm)) comment(res) <- comm
    if (!is.na(slot(res, "projargs"))) .sp_CRS_cache[[input_projargs]] <- res

    res
}
if (!isGeneric("wkt"))
	setGeneric("wkt", function(obj)
		standardGeneric("wkt"))

setMethod("wkt", signature(obj = "CRS"),
	function(obj) {
                comm <- comment(obj)
		comm
        }
)


"print.CRS" <- function(x, ...)
{
    cat("Coordinate Reference System:\n")
    pst <- paste(strwrap(x@projargs), collapse="\n")
    if (nchar(pst) < 40) cat(paste("Deprecated Proj.4 representation:", pst, "\n"))
    else cat(paste("Deprecated Proj.4 representation:\n", pst, "\n"))
    wkt <- wkt(x)
    if (!is.null(wkt)) {
        cat("WKT2 2019 representation:\n")
        cat(wkt, "\n")
    }
    invisible(pst)
}

setMethod("show", "CRS", function(object) print.CRS(object))

identicalCRS = function(x, y) {
	if (! missing(y)) {
            if (inherits(x, "ST")) x <- slot(slot(x, "sp"), "proj4string")
            else if (inherits(x, "Raster")) x <- slot(x, "crs")
            else x <- slot(x, "proj4string")
            if (inherits(y, "ST")) y <- slot(slot(y, "sp"), "proj4string")
            else if (inherits(y, "Raster")) y <- slot(y, "crs")
            else y <- slot(y, "proj4string")
	    identicalCRS1(rebuild_CRS(x), rebuild_CRS(y))
	} else { # x has to be list:
		stopifnot(is.list(x))
                if (inherits(x[[1]], "Tracks")) {
                    x <- unlist(lapply(x, function(j) {
                        y <- slot(j, "tracks") 
                          if (!is.null(y)) lapply(y, function(l) 
                            if (!is.null(l)) slot(l, "sp"))}))
                }
		if (length(x) > 1) {
                    if (inherits(x[[1]], "ST")) 
                        x[[1]] <- slot(slot(x[[1]], "sp"), "proj4string")
                    else if (inherits(x[[1]], "Raster"))
                        x[[1]] <- slot(x[[1]], "crs")
                    else x[[1]] <- slot(x[[1]], "proj4string")
		    p1 = rebuild_CRS(x[[1]])
		    !any(!sapply(x[-1], function(p2) {
                        if (inherits(p2, "ST")) 
                            p2 <- slot(slot(p2, "sp"), "proj4string")
                        else if (inherits(p2, "Raster")) p2 <- slot(p2, "crs")
                        else p2 <- slot(p2, "proj4string")
                        identicalCRS1(rebuild_CRS(p2), p1)}))
		} else
			TRUE
	}
}

identicalCRS1 = function(x, y) {
  args_x <- strsplit(x@projargs, " +")[[1]]
  args_y <- strsplit(y@projargs, " +")[[1]]
  setequal(args_x, args_y)
}
#https://github.com/inlabru-org/inlabru/issues/178
is.na.CRS = function(x) {
	is.na(x@projargs) && is.null(comment(x))
}
