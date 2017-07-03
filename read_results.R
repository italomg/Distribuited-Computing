library("ggplot2")

full = read.csv("./results/full.log", header = F, stringsAsFactors = F)
elephant = read.csv("./results/elephant.log", header = F, stringsAsFactors = F)
seahorse = read.csv("./results/seahorse.log", header = F, stringsAsFactors = F)
triplesp = read.csv("./results/triplesp.log", header = F, stringsAsFactors = F)

fulldata = rbind(
  full,
  elephant,
  seahorse,
  triplesp
)

names(fulldata) <- "output_line" 

results <- split(fulldata, f = rep(1:(nrow(fulldata)/10), each = 10))

read_result <- function(df) {
  
  output <- lapply(strsplit(df$output_line, "[ :]"), function(x) x[x != ""])
  num_threads <- as.numeric(gsub(",", ".",output[[2]][8]))
  img_size <- as.numeric(gsub(",", ".",output[[2]][6]))
  time_allocation <- as.numeric(gsub(",", ".",output[[3]][4]))
  time_algorithm <- as.numeric(gsub(",", ".",output[[5]][4]))
  time_ioops <- as.numeric(gsub(",", ".",output[[7]][5]))
  time_elapsed <- as.numeric(gsub(",", ".",output[[9]][4]))
 
  results <- data.frame(
    num_hosts = 1, # Change manually according to GCP setup
    num_threads = num_threads,
    img_size = img_size,
    time_allocation = time_allocation,
    time_algorithm = time_algorithm,
    time_ioops = time_ioops,
    time_elapsed = time_elapsed
  )
  
}

results <- do.call("rbind", lapply(results, read_result))


fulldata = rbind(
  results
)

write.csv(fulldata, file = "./results/results.csv")

 fig1 <- ggplot(data = fulldata, aes(x = as.factor(img_size), y = time_elapsed, color = type)) +
   geom_boxplot() +
#   facet_wrap(~imsize, scales = "free", labeller = "label_both") +
   ggtitle("Tempo de Execução x Tamanho da Imagem em Pixels") +
   xlab("Tamanho da Imagem em Pixels") +
   ylab("Tempo de execução (s)") +
   guides(color = guide_legend(title="Implementação")) +
   theme(plot.title = element_text(hjust = 0.5, vjust = 5, size = 20),
         strip.text = element_text(size= 16),
         axis.title = element_text(size = 16),
         legend.title = element_text(size = 16),
         legend.text = element_text(size = 16),
         axis.text = element_text(size = 12),
         axis.title.y=element_text(vjust=5),
         axis.title.x=element_text(vjust=-10),
         plot.margin = unit(c(1,1,1,1), "cm"))

pdf("resultado.pdf", width = 16, height = 9)
dev.off()

dados <- read.csv("./results/results.csv")
library("dplyr")

select(dados, num_hosts, num_threads, img_size, time_elapsed, time_allocation, time_algorithm, time_ioops)

grouped_result <- group_by(dados, num_hosts, num_threads, img_size)

summarised_result <- summarise(grouped_result,
                               media_time_elapsed = mean(time_elapsed, na.rm = TRUE),
                               desv_pad_time_elapsed = sd(time_elapsed),
                               media_time_allocation = mean(time_allocation, na.rm = TRUE),
                               desv_pad_time_allocation = sd(time_allocation),
                               media_time_algorithm = mean(time_algorithm, na.rm = TRUE),
                               desv_pad_time_algorithm = sd(time_algorithm),
                               media_time_ioops = mean(time_ioops, na.rm = TRUE),
                               desv_pad_time_ioops = sd(time_ioops))


write.csv(summarised_result, file = "./results/summarised_result.csv")  

fig2 <- ggplot(data=summarised_result, aes(x = factor(img_size), y=media_time_algorithm, fill=type)) +
  geom_bar(stat="identity", position=position_dodge())+
  #   facet_wrap(~imsize, scales = "free", labeller = "label_both") +
  ggtitle("Média do Tempo de Execução x Tamanho da Imagem Pixels") +
  xlab("Tamanho da Imagem Pixels") +
  ylab("Tempo de execução (s)") +
  guides(color = guide_legend(title="Implementação")) +
  theme(plot.title = element_text(hjust = 0.5, vjust = 5, size = 20),
        strip.text = element_text(size= 16),
        axis.title = element_text(size = 16),
        legend.title = element_text(size = 16),
        legend.text = element_text(size = 16),
        axis.text = element_text(size = 12),
        axis.title.y=element_text(vjust=5),
        axis.title.x=element_text(vjust=-10),
        plot.margin = unit(c(1,1,1,1), "cm"))

pdf("resultado_bar.pdf", width = 16, height = 9)
print(fig2)
dev.off() 

 ######################################

# plots <- list()
# current_plot <- 1

# sizes <- unique(results$img_size)
# for (s in sizes) {
#   df <- results[results$img_size == s]
#   plots[[current_plot]] <- list()
#   plots[[current_plot]][["fig"]] <- ggplot(data = df, 
#     aes(x = as.factor(nthreads), y = real, color = algorithm)) +
#     geom_boxplot() +
#     facet_wrap(~image, scales = "free") +
#     ggtitle("Tempo de Execução x Número de Threads", 
#             subtitle = sprintf("Tamanho da imagem: %s (Sem I/O)", s)) +
#     xlab("Número de threads") +
#     ylab("Tempo de execução (s)") +
#     guides(color = guide_legend(title="Implementação")) +
#     theme(plot.title = element_text(hjust = 0.5, vjust = 5, size = 20),
#           plot.subtitle = element_text(hjust = 0.5, size = 14, vjust = 5),
#           strip.text = element_text(size= 16),
#           axis.title = element_text(size = 16),
#           legend.title = element_text(size = 12),
#           legend.text = element_text(size = 12),
#           axis.text = element_text(size = 12),
#           axis.title.y=element_text(vjust=5),
#           axis.title.x=element_text(vjust=-65),
#           plot.margin = unit(c(1,1,1,1), "cm"))
#   plots[[current_plot]][["filename"]] <- sprintf("BoxplotSize%s.pdf", s)
#   current_plot <- current_plot + 1
# }

# for (p in plots) {
#   pdf(paste("./plots/", p[["filename"]], sep = ""), width = 16, height = 9)
#   print(p)
#   dev.off()
# }

# write.csv(results, file = "./results/results.csv")
