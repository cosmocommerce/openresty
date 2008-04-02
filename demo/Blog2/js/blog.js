var account = 'eeee';
var host = 'http://resty.eeeeworks.org';
//var host = 'http://10.62.136.86';

var openresty = null;
var savedAnchor = null;
var itemsPerPage = 5;
var loadingCount = 0;
var waitMessage = null;
var timer = null;

$(window).ready(init);

function error (msg) {
    alert(msg);
}

function debug (msg) {
    $("#copyright").append(msg + "<br/>");
}

$.fn.postprocess = function (clas, options) {
    return this.find("a[@href^='#']").each( function () {
        var anchor = $(this).attr('href').replace(/^\#/, '');
        //debug("Anchor: " + anchor);
        $(this).click( function () {
            //debug(location.hash);
            location.hash = anchor;
            //alert(location.hash);
            if (savedAnchor == anchor) savedAnchor = null;
            dispatchByAnchor();
        } );
    } );
};

//var count = 0;;
function setStatus (isLoading, category) {
    if (isLoading) {
        if (++loadingCount == 1) {
            if (jQuery.browser.opera)
                $(waitMessage).css('top', '2px');
            else
                $(waitMessage).show();
        }
    } else {
        loadingCount--;
        if (loadingCount < 0) loadingCount = 0;
        if (loadingCount == 0) {
            // the reason we use this hack is to work around
            // a rendering bug in Win32 build of Opera
            // (at least 9.25 and 9.26)
            if (jQuery.browser.opera)
                $(waitMessage).css('top', '-200px');
            else
                $(waitMessage).hide();

        }
    }
    //count++;
    //debug("[" + count + "] setStatus: " + category + ": " + loadingCount + "(" + isLoading + ")");
}

function init () {
    loadingCount = 0;
    waitMessage = document.getElementById('wait-message');
    //var host = 'http://10.62.136.86';
    //var host = 'http://127.0.0.1';
    openresty = new OpenAPI.Client(
        { server: host, user: account + '.Public' }
    );
    //openresty.formId = 'new_model';
    if (timer) {
        clearInterval(timer);
    }
    dispatchByAnchor();
    //timer = setInterval(dispatchByAnchor, 500);
    getSidebar();
}

function resetAnchor () {
    var anchor = location.hash;
    location.hash = anchor.replace(/^\#/, '');
}

function dispatchByAnchor () {
    //debug(location.hash);
    var anchor = location.hash;
    anchor = anchor.replace(/^\#/, '');
    if (savedAnchor == anchor)
        return;
    if (anchor == "") {
        anchor = 'main';
        location.hash = 'main';
    }
    savedAnchor = anchor;
    loadingCount = 0;

    var match = anchor.match(/^post-(\d+)(:comments|comment-(\d+))?/);
    if (match) {
        var postId = match[1];
        //alert("Post ID: " + postId);
        getPost(postId);
        return;
    }
    match = anchor.match(/^(?:post-list|post-list-(\d+))$/);
    var page = 1;
    //alert(anchor + " " + location.hash);
    if (match)
        page = parseInt(match[1]) || 1;
    else if (anchor != 'main')
        top.location.hash = 'main';

    setStatus(true, 'renderPostList');
    openresty.callback = renderPostList;
    openresty.get('/=/model/Post/~/~', {
        count: itemsPerPage,
        order_by: 'id:desc',
        offset: itemsPerPage * (page - 1),
        limit: itemsPerPage
    });
    setStatus(true, 'renderPager');
    openresty.callback = function (res) { renderPager(res, page); };
    openresty.get('/=/view/RowCount/model/Post');
    $(".blog-top").attr('id', 'post-list-' + page);
}

function getSidebar () {
    getCalendar();
    getRecentPosts();
    getRecentComments();
}

function getCalendar (year, month) {
    if (year == undefined || month == undefined) {
        var now = new Date();
        year = now.getFullYear();
        month = now.getMonth();
    }
    var date = new Date(year, month, 1);
    var first_day_of_week = date.getDay();
    var end_of_month;
    if (month == 11) {
        end_of_month = 31;
    } else {
        var delta = new Date(year, month + 1, 1) - date;
        end_of_month = Math.round(delta/1000/60/60/24);
    }
    //alert(year);
    //alert(month);
    $(".module-calendar").html(
        Jemplate.process(
            'calendar.tt',
            {
                year: year,
                month: month,
                first_day_of_week: first_day_of_week,
                end_of_month: end_of_month
            }
        )
    ).postprocess();

    // We need this 0 timeout hack for IE 6 :(
    setTimeout( function () {
        setStatus(true, 'renderPostsInCalendar');
        openresty.callback = function (res) {
            renderPostsInCalendar(res, year, month);
        };
        openresty.get('/=/view/PostsByMonth/~/~', { year: year, month: month + 1 });
    }, 0 );
}

function renderPostsInCalendar (res, year, month) {
    setStatus(false, 'renderPostsInCalendar');
    //alert("hey!");
    if (!openresty.isSuccess(res)) {
        error("Failed to fetch posts for calendar: " +
            res.error);
    } else {
        //alert(res.error);
        var prev_day = 0;
        for (var i = 0; i < res.length; i++) {
            var line = res[i];
            if (prev_day == line.day) continue;
            prev_day = line.day;
            var id = 'day-' + year + '-' + month + '-' + line.day;
            //alert("ID: " + id);
            var cell = $("#" + id);
            if (cell.length == 0) return;
            //alert("cell html: " + cell.html());
            cell.html('<a href="#post-' + line.id + '"><b>' +
                cell.html() + '</b></a>').postprocess();
        }
    }
}

function getRecentComments (offset) {
    if (!offset) offset = 0;
    setStatus(true, 'renderRecentComments');
    openresty.callback = function (res) { renderRecentComments(res, offset, 6) };
    openresty.get('/=/view/RecentComments/limit/6', { offset: offset });
}

function renderRecentComments (res, offset, count) {
    setStatus(false, 'renderRecentComments');
    if (!openresty.isSuccess(res)) {
        error("Failed to get the recent comments: " + res.error);
    } else {
        //alert("Get the recent comments: " + res.error);
        var html = Jemplate.process(
            'recent-comments.tt',
            { comments: res, offset: offset, count: count  }
        );
        $("#recent-comments").html(html).postprocess();
    }
}

function getRecentPosts (offset) {
    if (!offset) offset = 0;
    setStatus(true, 'renderRecentPosts');
    openresty.callback = function (res) { renderRecentPosts(res, offset, 6) };
    openresty.get('/=/view/RecentPosts/limit/6', { offset: offset });
}

function renderRecentPosts (res, offset, count) {
    setStatus(false, 'renderRecentPosts');
    if (!openresty.isSuccess(res)) {
        error("Failed to get the recent posts: " + res.error);
    } else {
        //alert("Get the recent comments: " + res.error);
        var html = Jemplate.process(
            'recent-posts.tt',
            { posts: res, offset: offset, count: count  }
        );
        $("#recent-posts").html(html).postprocess();
    }
}

function postComment (form) {
    var data = {};
    data.sender = $("#comment-author").val();
    data.email = $("#comment-email").val();
    data.url = $("#comment-url").val();
    data.body = $("#comment-text").val();
    data.post = $("#comment-for").val();
    //alert(JSON.stringify(data));
    if (!data.sender) {
        error("Name is required.");
        return false;
    }
    if (!data.email) {
        error("Email address is required.");
        return false;
    }
    if (!data.body) {
        error("Comment body is required.");
        return false;
    }

    //openresty.purge();
    setStatus(true, 'afterPostComment');
    openresty.callback = afterPostComment;
    //openresty.formId = 'comment-form';
    openresty.postByGet(data, '/=/model/Comment/~/~');
    return false;
}

function afterPostComment (res) {
    setStatus(false, 'afterPostComment');
    //alert("HERE!!!");
    if (!openresty.isSuccess(res)) {
        error("Failed to post the comment: " + res.error);
    } else {
        //alert(res.error);
        $("#comment-text").val('');
        var spans = $(".comment-count");
        var commentCount = parseInt(spans.text());
        var postId = spans.attr('post');

        //debug(JSON.stringify(res));
        var commentId;
        var match = res.last_row.match(/\d+$/);
        if (match.length) commentId = match[0];
        location.hash = 'post-' + postId + ':' +
            (commentId ? 'comment-' + commentId : 'comments');
        openresty.callback = function (res) {
            if (!openresty.isSuccess(res)) {
                error("Failed to increment the comment count for post " +
                    postId + ": " + res.error);
            } else {
                spans.text(commentCount + 1);
            }
        };
        openresty.putByGet(
            { comments: commentCount + 1 },
            '/=/model/Post/id/' + postId
        );
        getRecentComments(0);
    }
}

function getPost (id) {
    //alert("Go to Post " + id);
    $(".blog-top").attr('id', 'post-' + id);
    //alert($(".blog-top").attr('id'));
    setStatus(true, 'renderPost');
    openresty.callback = renderPost;
    openresty.get('/=/model/Post/id/' + id);
}

function renderPost (res) {
    setStatus(false, 'renderPost');
    //alert(JSON.stringify(post));
    if (!openresty.isSuccess(res)) {
        error("Failed to render post: " + res.error);
    } else {
        var post = res[0];
        $("#beta-inner.pkg").html(
            Jemplate.process('post-page.tt', { post: post })
        ).postprocess();

        openresty.callback = function (res) {
            renderPrevNextPost(post.id, res);
        };
        openresty.get('/=/view/PrevNextPost/current/' + post.id);

        setStatus(true, 'renderComments');
        openresty.callback = renderComments;
        openresty.get('/=/model/Comment/post/' + post.id);
        $("#beta-pager.pkg").html('');
    }
}

function renderPrevNextPost (currentId, res) {
    if (!openresty.isSuccess(res)) {
        error("Failed to render prev next post navigation: " +
            res.error);
    } else {
        //alert("Going to render prev next post navigation: " + res.error);
        $(".content-nav").html(
            Jemplate.process('nav.tt', { posts: res, current: currentId })
        ).postprocess();
        resetAnchor();
    }
}

function renderComments (res) {
    setStatus(false, 'renderComments');
    //alert("Comments: " + res.error);
    if (!openresty.isSuccess(res)) {
        error("Failed to render post list: " + res.error);
    } else {
        $(".comments-content").html(
            Jemplate.process('comments.tt', { comments: res })
        );
        resetAnchor();
    }
}

function renderPostList (res) {
    setStatus(false, 'renderPostList');
    if (!openresty.isSuccess(res)) {
        error("Failed to render post list: " + res.error);
    } else {
        //alert(JSON.stringify(data));
        $("#beta-inner.pkg").html(
            Jemplate.process('post-list.tt', { post_list: res })
        ).postprocess();
    }
    resetAnchor();
}

function renderPager (res, page) {
    setStatus(false, 'renderPager');
    if (!openresty.isSuccess(res)) {
        error("Failed to render pager: " + res.error);
    } else {
        var pageCount = Math.ceil(parseInt(res[0].count) / itemsPerPage);
        if (pageCount < 2) return;
        $("#beta-pager.pkg").html(
            Jemplate.process(
                'pager.tt',
                { page: page, page_count: pageCount, title: 'Pages' }
            )
        ).postprocess();
        resetAnchor();
    }
}
