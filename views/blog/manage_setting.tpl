<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title>{{i18n .Lang "blog.blog_setting"}} - Powered by MinDoc</title>

    <!-- Bootstrap -->
    <link href="{{cdncss "/static/bootstrap/css/bootstrap.min.css"}}" rel="stylesheet">
    <link href="{{cdncss "/static/font-awesome/css/font-awesome.min.css"}}" rel="stylesheet">
    <link href="{{cdncss "/static/css/main.css" "version"}}" rel="stylesheet">
    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
    <script src="/static/html5shiv/3.7.3/html5shiv.min.js"></script>
    <script src="/static/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
</head>
<body>
<div class="manual-reader">
    {{template "widgets/header.tpl" .}}
    <div class="container manual-body">
        <div class="row">
            <div class="page-left">
                <ul class="menu">
                    <li {{if eq .ControllerName "BookController"}}class="active"{{end}}><a href="{{urlfor "BookController.Index"}}" class="item"><i class="fa fa-sitemap" aria-hidden="true"></i> {{i18n .Lang "common.my_project"}}</a> </li>
                    <li {{if eq .ControllerName "BlogController"}}class="active"{{end}}><a href="{{urlfor "BlogController.ManageList"}}" class="item"><i class="fa fa-file" aria-hidden="true"></i> {{i18n .Lang "common.my_blog"}}</a> </li>
                </ul>
            </div>
            <div class="page-right">
                <div class="m-box">
                    <div class="box-head">
                        <strong class="box-title"> {{i18n .Lang "blog.blog_setting"}}</strong>
                    </div>
                </div>
                <div class="box-body">
                    <form method="post" id="gloablEditForm" action="{{urlfor "BlogController.ManageSetting"}}">
                        <input type="hidden" name="id" id="blogId" value="{{.Model.BlogId}}">
                        <input type="hidden" name="identify" value="{{.Model.BlogIdentify}}">
                        <input type="hidden" name="document_id" value="{{.Model.DocumentId}}">
                        <input type="hidden" name="order_index" value="{{.Model.OrderIndex}}">
                        <div class="form-group">
                            <label>{{i18n .Lang "blog.title"}}</label>
                            <input type="text" class="form-control" name="title" id="title" placeholder="{{i18n .Lang "blog.title"}}" value="{{.Model.BlogTitle}}">
                        </div>


                        <div class="form-group">
                            <label>{{i18n .Lang "blog.type"}}</label>
                            <div class="radio">
                                <label class="radio-inline">
                                    <input type="radio" {{if eq .Model.BlogType 0}}checked{{end}} name="blog_type" value="0">{{i18n .Lang "blog.normal_blog"}}<span class="text"></span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" {{if eq .Model.BlogType 1}}checked{{end}} name="blog_type" value="1">{{i18n .Lang "blog.link_blog"}}<span class="text"></span>
                                </label>
                            </div>
                        </div>
                        <div class="form-group" id="blogLinkDocument"{{if ne .Model.BlogType 1}} style="display: none;" {{end}}>
                            <label>{{i18n .Lang "blog.ref_doc"}}</label>
                            <div class="row">
                                <div class="col-sm-6">
                                    <input type="text" class="form-control" placeholder="{{i18n .Lang "message.input_proj_id_pls"}}" name="bookIdentify" value="{{.Model.BookIdentify}}">
                                </div>
                                <div class="col-sm-6">
                                    <input type="text" class="form-control" placeholder="{{i18n .Lang "message.input_doc_id_pls"}}" name="documentIdentify" value="{{.Model.DocumentIdentify}}">
                                </div>
                            </div>

                        </div>
                        <div class="form-group">
                            <label>{{i18n .Lang "blog.blog_status"}}</label>
                            <div class="radio">
                                <label class="radio-inline">
                                    <input type="radio" {{if eq .Model.BlogStatus "public"}}checked{{end}} name="status" value="public">{{i18n .Lang "blog.public"}}<span class="text"></span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" {{if eq .Model.BlogStatus "password"}}checked{{end}} name="status" value="password">{{i18n .Lang "blog.encryption"}}<span class="text"></span>
                                </label>
                                <label class="radio-inline">
                                    <input type="radio" {{if eq .Model.BlogStatus "private"}}checked{{end}} name="status" value="private">{{i18n .Lang "blog.private"}}<span class="text"></span>
                                </label>
                            </div>
                        </div>
                        <div class="form-group"{{if ne .Model.BlogStatus "password"}} style="display: none;"{{end}} id="blogPassword">
                            <label>{{i18n .Lang "blog.blog_pwd"}}</label>
                            <input type="password" class="form-control" name="password" id="password" placeholder="{{i18n .Lang "blog.blog_pwd"}}" value="{{.Model.Password}}" maxlength="20">
                        </div>
                        <div class="form-group">
                            <label>{{i18n .Lang "blog.blog_digest"}}</label>
                            <textarea rows="3" class="form-control" name="excerpt" style="height: 90px" placeholder="{{i18n .Lang "blog.blog_digest"}}">{{.Model.BlogExcerpt}}</textarea>
                            <p class="text">{{i18n .Lang "message.blog_digest_tips"}}</p>
                        </div>
                        {{if gt .Model.BlogId 0}}
                        <div class="form-group">
                            <label>Access Token</label>
                            <div class="input-group">
                                <input type="text" class="form-control" id="blogAppendApiToken" value="{{.BlogAppendAPIToken}}" readonly>
                                <span class="input-group-btn">
                                    <button type="button" class="btn btn-default" id="btnCopyBlogApiToken">复制 Token</button>
                                    <button type="button" class="btn btn-default" id="btnResetBlogApiToken" data-loading-text="{{i18n .Lang "message.processing"}}">随机重置</button>
                                </span>
                            </div>
                            <p class="text">Token 用于定位并授权访问当前文章，重置后旧 Token 会立即失效。</p>
                        </div>
                        <div class="form-group">
                            <label>API 调用示例</label>
                            <textarea class="form-control" id="blogAppendAPIExample" rows="10" style="font-family: monospace; resize: vertical;" readonly>{{.BlogAppendAPIExample}}</textarea>
                            <button type="button" class="btn btn-default" id="btnCopyBlogApiExample" style="margin-top: 8px;">复制示例</button>
                            <p class="text">type=add 时按 position（head/tail）添加，type=overwrite 时覆盖全文；type 默认 add，position 默认 tail。</p>
                        </div>
                        {{end}}

                        <div class="form-group">
                            <button type="submit" id="btnSaveBlogInfo" class="btn btn-success" data-loading-text="{{i18n .Lang "message.processing"}}">{{i18n .Lang "common.save"}}</button>
                            <a href="{{.Referer}}" title="{{i18n .Lang "doc.backward"}}" class="btn btn-info">{{i18n .Lang "doc.backward"}}</a>
                            <span id="form-error-message" class="error-message"></span>
                        </div>
                    </form>

                    <div class="clearfix"></div>

                </div>
            </div>
        </div>
    </div>
    {{template "widgets/footer.tpl" .}}
</div>


<script src="{{cdnjs "/static/jquery/1.12.4/jquery.min.js"}}" type="text/javascript"></script>
<script src="{{cdnjs "/static/bootstrap/js/bootstrap.min.js"}}" type="text/javascript"></script>
<script src="{{cdnjs "/static/js/jquery.form.js"}}" type="text/javascript"></script>
<script src="{{cdnjs "/static/js/main.js"}}" type="text/javascript"></script>
    <script type="text/javascript">
    $(function () {
        const blogId = Number($("#blogId").val());
        const resetApiTokenURL = {{urlfor "BlogController.ResetAPIToken"}};
        $("#gloablEditForm").ajaxForm({
            beforeSubmit : function () {
                var title = $.trim($("#title").val());

                if (title === ""){
                    return showError("{{i18n .Lang "message.blog_title_empty"}}");
                }
                $("#btnSaveBlogInfo").button("loading");
            },success : function ($res) {
                if($res.errcode === 0) {
                    showSuccess("{{i18n .Lang "message.success"}}");
                    $("#blogId").val($res.data.blog_id);
                    if (blogId === 0) {
                        // 优化新增文章后直接跳转到编辑页面
                        window.location.href = {{urlfor "BlogController.ManageEdit" ":id" "xxx"}}.replace("xxx", $res.data.blog_id)
                    }
                }else{
                    showError($res.message);
                }
                $("#btnSaveBlogInfo").button("reset");
            }, error : function () {
                showError("{{i18n .Lang "message.system_error"}}");
                $("#btnSaveBlogInfo").button("reset");
            }
        }).find("input[name='status']").change(function () {
            var $status = $(this).val();
            if($status === "password"){
                $("#blogPassword").show();
            }else{
                $("#blogPassword").hide();
            }
        });
        $("#gloablEditForm").find("input[name='blog_type']").change(function () {
            var $link = $(this).val();
            if($link == 1){
                $("#blogLinkDocument").show();
            }else{
                $("#blogLinkDocument").hide();
            }
        });
        async function copyBlogAPIValue(selector, emptyMessage) {
            var $source = $(selector);
            var value = $source.val();
            if (!value) {
                showError(emptyMessage);
                return;
            }
            try {
                await navigator.clipboard.writeText(value);
                showSuccess("复制成功");
            } catch (e) {
                $source.trigger("focus").trigger("select");
                try {
                    document.execCommand("copy");
                    showSuccess("复制成功");
                } catch (err) {
                    showError("复制失败，请手动复制");
                }
            }
        }
        $("#btnCopyBlogApiToken").on("click", function () {
            copyBlogAPIValue("#blogAppendApiToken", "Token 为空");
        });
        $("#btnCopyBlogApiExample").on("click", function () {
            copyBlogAPIValue("#blogAppendAPIExample", "API 示例为空");
        });
        $("#btnResetBlogApiToken").on("click", function () {
            if (!blogId) {
                showError("请先保存文章，再生成 token");
                return;
            }
            var $btn = $(this).button("loading");
            $.post(resetApiTokenURL, {blog_id: blogId}, function (res) {
                if (res.errcode === 0) {
                    if (res.data.api_token) {
                        $("#blogAppendApiToken").val(res.data.api_token);
                    }
                    if (res.data.api_append_example) {
                        $("#blogAppendAPIExample").val(res.data.api_append_example);
                    }
                    showSuccess("Token 已重置");
                } else {
                    showError(res.message);
                }
            }).fail(function () {
                showError("{{i18n .Lang "message.system_error"}}");
            }).always(function () {
                $btn.button("reset");
            });
        });
    });
</script>
</body>
</html>
