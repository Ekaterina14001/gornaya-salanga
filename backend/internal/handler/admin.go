package handler

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/gornaya-salanga/backend/internal/middleware"
	"github.com/gornaya-salanga/backend/internal/model"
	"github.com/gornaya-salanga/backend/pkg/response"
)

func (h *Handler) AdminDashboard(c *gin.Context) {
	data, err := h.admin.Dashboard(c.Request.Context())
	if err != nil {
		response.Internal(c, "dashboard failed")
		return
	}
	response.OK(c, data)
}

func (h *Handler) AdminListUsers(c *gin.Context) {
	page, pageSize := pagination(c)
	q := c.Query("q")
	result, err := h.admin.ListUsers(c.Request.Context(), q, page, pageSize)
	if err != nil {
		response.Internal(c, "list users failed")
		return
	}
	response.OK(c, result)
}

func (h *Handler) AdminGetUser(c *gin.Context) {
	user, err := h.admin.GetUser(c.Request.Context(), c.Param("id"))
	if err != nil {
		response.NotFound(c, "user not found")
		return
	}
	response.OK(c, user)
}

func (h *Handler) AdminBlockUser(c *gin.Context) {
	var body struct {
		Blocked bool `json:"blocked"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	if err := h.admin.SetBlocked(c.Request.Context(), c.Param("id"), body.Blocked); err != nil {
		response.Internal(c, "block failed")
		return
	}
	response.OK(c, gin.H{"blocked": body.Blocked})
}

func (h *Handler) AdminAdjustUserBonus(c *gin.Context) {
	var body struct {
		Type        string  `json:"type"`
		Amount      float64 `json:"amount"`
		Description string  `json:"description"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	adminID := middleware.GetUserID(c)
	tx, err := h.admin.AdjustUserBonus(c.Request.Context(), adminID, c.Param("id"), body.Type, body.Amount, body.Description)
	if err != nil {
		msg := err.Error()
		if strings.Contains(msg, "bonus_source") || strings.Contains(msg, "22P02") {
			response.BadRequest(c, "источник операции не поддерживается — выполните миграцию 000006")
			return
		}
		if msg == "insufficient balance" || msg == "user is blocked" {
			response.BadRequest(c, err.Error())
			return
		}
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, tx)
}

func (h *Handler) AdminGetBonusConfig(c *gin.Context) {
	cfg, err := h.admin.GetBonusConfig(c.Request.Context())
	if err != nil {
		response.Internal(c, "get config failed")
		return
	}
	response.OK(c, cfg)
}

func (h *Handler) AdminUpdateBonusConfig(c *gin.Context) {
	var cfg model.BonusConfig
	if err := c.ShouldBindJSON(&cfg); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	adminID := middleware.GetUserID(c)
	updated, err := h.admin.UpdateBonusConfig(c.Request.Context(), adminID, &cfg)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, updated)
}

func (h *Handler) AdminBonusConfigAudit(c *gin.Context) {
	items, err := h.admin.BonusConfigAudit(c.Request.Context())
	if err != nil {
		response.Internal(c, "audit failed")
		return
	}
	response.OK(c, items)
}

func (h *Handler) AdminListTransactions(c *gin.Context) {
	page, pageSize := pagination(c)
	userID := c.Query("userId")
	txType := c.Query("type")
	result, err := h.admin.ListTransactions(c.Request.Context(), userID, txType, page, pageSize)
	if err != nil {
		response.Internal(c, "list transactions failed")
		return
	}
	response.OK(c, result)
}

func (h *Handler) AdminListPOSKeys(c *gin.Context) {
	keys, err := h.admin.ListPOSKeys(c.Request.Context())
	if err != nil {
		response.Internal(c, "list keys failed")
		return
	}
	response.OK(c, keys)
}

func (h *Handler) AdminCreatePOSKey(c *gin.Context) {
	var body struct {
		System string `json:"system"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	key, err := h.admin.CreatePOSKey(c.Request.Context(), body.System)
	if err != nil {
		response.Internal(c, "create key failed")
		return
	}
	response.Created(c, key)
}

func (h *Handler) AdminRevokePOSKey(c *gin.Context) {
	if err := h.admin.RevokePOSKey(c.Request.Context(), c.Param("id")); err != nil {
		response.Internal(c, "revoke failed")
		return
	}
	response.NoContent(c)
}

func (h *Handler) AdminPOSLogs(c *gin.Context) {
	page, pageSize := pagination(c)
	result, err := h.admin.POSLogs(c.Request.Context(), page, pageSize)
	if err != nil {
		response.Internal(c, "list logs failed")
		return
	}
	response.OK(c, result)
}

func (h *Handler) AdminUpdateAbout(c *gin.Context) {
	var body struct {
		Title        string   `json:"title"`
		BodyMarkdown string   `json:"bodyMarkdown"`
		Photos       []string `json:"photos"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	data, err := h.admin.UpdateAbout(c.Request.Context(), body.Title, body.BodyMarkdown, body.Photos)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, data)
}

func (h *Handler) AdminUpdateRules(c *gin.Context) {
	var body struct {
		Title        string `json:"title"`
		Body         string `json:"body"`
		BodyMarkdown string `json:"bodyMarkdown"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	content := body.Body
	if content == "" {
		content = body.BodyMarkdown
	}
	data, err := h.admin.UpdateRules(c.Request.Context(), c.Param("type"), body.Title, content)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, data)
}

func (h *Handler) AdminCreateService(c *gin.Context) {
	var body struct {
		Name        string  `json:"name"`
		Description string  `json:"description"`
		Price       float64 `json:"price"`
		Category    string  `json:"category"`
		SortOrder   int     `json:"sortOrder"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	data, err := h.admin.CreateService(c.Request.Context(), body.Name, body.Description, body.Price, body.Category, body.SortOrder)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.Created(c, data)
}

func (h *Handler) AdminUpdateService(c *gin.Context) {
	var body struct {
		Name        *string  `json:"name"`
		Description *string  `json:"description"`
		Price       *float64 `json:"price"`
		Category    *string  `json:"category"`
		SortOrder   *int     `json:"sortOrder"`
		Active      *bool    `json:"active"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	data, err := h.admin.UpdateService(c.Request.Context(), c.Param("id"), body.Name, body.Description, body.Price, body.Category, body.SortOrder, body.Active)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, data)
}

func (h *Handler) AdminDeleteService(c *gin.Context) {
	if err := h.admin.DeleteService(c.Request.Context(), c.Param("id")); err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.NoContent(c)
}

func (h *Handler) AdminSyncSalangaServices(c *gin.Context) {
	result, err := h.content.SyncSalangaServices(c.Request.Context())
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, result)
}

func (h *Handler) AdminListServices(c *gin.Context) {
	items, err := h.admin.ListServices(c.Request.Context())
	if err != nil {
		response.Internal(c, "list services failed")
		return
	}
	response.OK(c, items)
}

func (h *Handler) AdminListHeadliners(c *gin.Context) {
	items, err := h.admin.ListHeadliners(c.Request.Context())
	if err != nil {
		response.Internal(c, "list headliners failed")
		return
	}
	response.OK(c, items)
}

func (h *Handler) AdminCreateHeadliner(c *gin.Context) {
	var body struct {
		Title     string `json:"title"`
		Subtitle  string `json:"subtitle"`
		ImageURL  string `json:"imageUrl"`
		LinkURL   string `json:"linkUrl"`
		SortOrder int    `json:"sortOrder"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.Title == "" {
		response.BadRequest(c, "title required")
		return
	}
	data, err := h.admin.CreateHeadliner(c.Request.Context(), body.Title, body.Subtitle, body.ImageURL, body.LinkURL, body.SortOrder)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.Created(c, data)
}

func (h *Handler) AdminUpdateHeadliner(c *gin.Context) {
	var body struct {
		Title     *string `json:"title"`
		Subtitle  *string `json:"subtitle"`
		ImageURL  *string `json:"imageUrl"`
		LinkURL   *string `json:"linkUrl"`
		SortOrder *int    `json:"sortOrder"`
		Active    *bool   `json:"active"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	data, err := h.admin.UpdateHeadliner(c.Request.Context(), c.Param("id"), body.Title, body.Subtitle, body.ImageURL, body.LinkURL, body.SortOrder, body.Active)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, data)
}

func (h *Handler) AdminDeleteHeadliner(c *gin.Context) {
	if err := h.admin.DeleteHeadliner(c.Request.Context(), c.Param("id")); err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.NoContent(c)
}

func (h *Handler) AdminCreateWebcam(c *gin.Context) {
	var body struct {
		Name                string `json:"name"`
		StreamURL           string `json:"streamUrl"`
		LocationDescription string `json:"locationDescription"`
		SortOrder           int    `json:"sortOrder"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	if body.Name == "" || body.StreamURL == "" {
		response.BadRequest(c, "name and streamUrl required")
		return
	}
	data, err := h.admin.CreateWebcam(c.Request.Context(), body.Name, body.StreamURL, body.LocationDescription, body.SortOrder)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.Created(c, data)
}

func (h *Handler) AdminUpdateWebcam(c *gin.Context) {
	var body struct {
		Name                *string `json:"name"`
		StreamURL           *string `json:"streamUrl"`
		LocationDescription *string `json:"locationDescription"`
		SortOrder           *int    `json:"sortOrder"`
		Active              *bool   `json:"active"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	data, err := h.admin.UpdateWebcam(c.Request.Context(), c.Param("id"), body.Name, body.StreamURL, body.LocationDescription, body.SortOrder, body.Active)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, data)
}

func (h *Handler) AdminCreateTrail(c *gin.Context) {
	var body struct {
		Name       string `json:"name"`
		Difficulty string `json:"difficulty"`
		Status     string `json:"status"`
		Comment    string `json:"comment"`
		SortOrder  int    `json:"sortOrder"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	if body.Name == "" {
		response.BadRequest(c, "name required")
		return
	}
	data, err := h.admin.CreateTrail(c.Request.Context(), body.Name, body.Difficulty, body.Status, body.Comment, body.SortOrder)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.Created(c, data)
}

func (h *Handler) AdminUpdateTrail(c *gin.Context) {
	var body struct {
		Name       *string `json:"name"`
		Difficulty *string `json:"difficulty"`
		Status     *string `json:"status"`
		Comment    *string `json:"comment"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	data, err := h.admin.UpdateTrail(c.Request.Context(), c.Param("id"), body.Name, body.Difficulty, body.Status, body.Comment)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, data)
}

func (h *Handler) AdminListSchedule(c *gin.Context) {
	items, err := h.admin.ListSchedule(c.Request.Context())
	if err != nil {
		response.Internal(c, "list schedule failed")
		return
	}
	response.OK(c, items)
}

func (h *Handler) AdminUpdateSchedule(c *gin.Context) {
	var body struct {
		OpenTime  *string `json:"openTime"`
		CloseTime *string `json:"closeTime"`
		Closed    *bool   `json:"closed"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	data, err := h.admin.UpdateSchedule(c.Request.Context(), c.Param("id"), body.OpenTime, body.CloseTime, body.Closed)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, data)
}

func (h *Handler) AdminListLifts(c *gin.Context) {
	items, err := h.admin.ListLifts(c.Request.Context())
	if err != nil {
		response.Internal(c, "list lifts failed")
		return
	}
	response.OK(c, items)
}

func (h *Handler) AdminUpdateLift(c *gin.Context) {
	var body struct {
		Name        *string `json:"name"`
		Status      *string `json:"status"`
		OpenTime    *string `json:"openTime"`
		CloseTime   *string `json:"closeTime"`
		Comment     *string `json:"comment"`
		Description *string `json:"description"`
		PricesText  *string `json:"pricesText"`
		Active      *bool   `json:"active"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	data, err := h.admin.UpdateLift(c.Request.Context(), c.Param("id"), body.Name, body.Status, body.OpenTime, body.CloseTime, body.Comment, body.Description, body.PricesText, body.Active)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, data)
}

func (h *Handler) AdminSyncSalangaLifts(c *gin.Context) {
	result, err := h.content.SyncSalangaLifts(c.Request.Context())
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, result)
}

func (h *Handler) AdminBroadcast(c *gin.Context) {
	var body struct {
		Title    string         `json:"title"`
		Body     string         `json:"body"`
		Type     string         `json:"type"`
		Audience string         `json:"audience"`
		Data     map[string]any `json:"data"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	count, err := h.admin.Broadcast(c.Request.Context(), body.Title, body.Body, body.Type, body.Audience, body.Data)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.Created(c, gin.H{"sent": count})
}

func (h *Handler) AdminPushStatus(c *gin.Context) {
	response.OK(c, gin.H{"pushEnabled": h.notif.PushEnabled()})
}

func (h *Handler) AdminListMessages(c *gin.Context) {
	status := c.DefaultQuery("status", "")
	items, err := h.admin.ListMessages(c.Request.Context(), status)
	if err != nil {
		response.Internal(c, "list messages failed")
		return
	}
	response.OK(c, items)
}

func (h *Handler) AdminReplyMessage(c *gin.Context) {
	var body struct {
		Reply string `json:"reply"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		response.BadRequest(c, "invalid body")
		return
	}
	msg, err := h.admin.ReplyMessage(c.Request.Context(), c.Param("id"), body.Reply)
	if err != nil {
		response.Internal(c, err.Error())
		return
	}
	response.OK(c, msg)
}

func (h *Handler) AdminExportTransactions(c *gin.Context) {
	csvData, err := h.admin.ExportTransactionsCSV(c.Request.Context())
	if err != nil {
		response.Internal(c, "export failed")
		return
	}
	c.Header("Content-Type", "text/csv; charset=utf-8")
	c.Header("Content-Disposition", "attachment; filename=transactions.csv")
	c.String(http.StatusOK, csvData)
}
