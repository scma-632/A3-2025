getwd()
setwd()
getwd()

## NSSO68 Multiple Regression Analysis

data <- read.csv("NSSO68.csv")
summary(data)
names(data)
head(data)
tail(data)

#install.packages("dplyr")
#install.packages("htmltools")
#install.packages("xfun")
#install.packages("knitr")
#install.packages("sass")
#install.packages("car")
#install.packages("lmtest")
#install.packages("rmarkdown")
#install.packages("bslib")

library(dplyr)
library(htmltools)
library(xfun)
library(knitr)
library(htmltools)
library(sass)
library(car)
library(lmtest)
library(rmarkdown)
library(bslib)

# Subset data to state assigned
subset_data <- data %>%
  filter(state_1 == 'KA') %>%
  select(foodtotal_q, MPCE_MRP, MPCE_URP,Age,Meals_At_Home,Possess_ration_card,Education, No_of_Meals_per_day)
print(subset_data)

sum(is.na(subset_data$MPCE_MRP))
sum(is.na(subset_data$MPCE_URP))
sum(is.na(subset_data$Age))
sum(is.na(subset_data$Possess_ration_card))
sum(is.na(data$Education))

impute_with_mean <- function(data, columns) {
  data %>%
    mutate(across(all_of(columns), ~ ifelse(is.na(.), mean(., na.rm = TRUE), .)))
}

# Columns to impute
columns_to_impute <- c("Education")

# Impute missing values with mean
data <- impute_with_mean(data, columns_to_impute)

sum(is.na(data$Education))

# Fit the regression model
model <- lm(foodtotal_q~ MPCE_MRP+MPCE_URP+Age+Meals_At_Home+Possess_ration_card+Education, data = subset_data)

# Print the regression results
print(summary(model))


library(car)
# Check for multicollinearity using Variance Inflation Factor (VIF)
vif(model) # VIF Value more than 8 its problematic

# Extract the coefficients from the model
coefficients <- coef(model)

# Construct the equation
equation <- paste0("y = ", round(coefficients[1], 2))
for (i in 2:length(coefficients)) {
  equation <- paste0(equation, " + ", round(coefficients[i], 6), "*x", i-1)
}
# Print the equation
print(equation)

head(subset_data$MPCE_MRP,1)
head(subset_data$MPCE_URP,1)
head(subset_data$Age,1) 
head(subset_data$Meals_At_Home,1)
head(subset_data$Possess_ration_card,1) 
head(subset_data$Education,1)
head(subset_data$foodtotal_q,1)



## IPL Regression Analysis
df_p = read.csv('IPL_ball_by_ball_updated till 2024.csv')
library(readxl)
df_s = read_excel('IPL SALARIES 2024.xlsx')


#install.packages('dplyr')
library(dplyr)
dput(names(df_p))
unique(df_p$wicket_confirmation)


# Print the column names of df_p to verify

print(colnames(df_p))

# Assuming the column names in df_p are correct as used in the select function
# If the column names differ, update them accordingly in the select function

# Perform the operations
df_bat <- df_p %>%
  select('Match.id', 'Season', 'Bowler', 'Striker', 'runs_scored', 'wicket_confirmation') %>%
  filter(Season %in% c('2023', '2022', '2021')) %>%
  group_by(Striker, Season) %>%
  summarise(avg_runs = sum(runs_scored, na.rm = TRUE)) %>%
  arrange(desc(avg_runs))

# Print the resulting data frame
print("Resulting df_bat:")
print(df_bat)

df_bat <- df_p %>%
  select(Match.id,Season,Bowler,Striker,runs_scored,wicket_confirmation)%>%
  filter((Season=='2023')|(Season=='2022')|(Season=='2021'))%>%
  group_by(Striker, Season) %>%
  summarise(avg_runs = sum(runs_scored, na.rm = TRUE))%>%
  arrange(desc(avg_runs))

head(df_bat,25)
df_bat$Striker


df_bow <- df_p %>%
  select(Match.id,Season,Bowler,Striker,runs_scored,wicket_confirmation)%>%
  filter((Season=='2023')|(Season=='2022')|(Season=='2021'))%>%
  group_by(Bowler, Season) %>%
  summarise(wicket = sum(wicket_confirmation, na.rm = TRUE))%>%
  arrange(desc(wicket))

dim(df_bat)
dim(df_bow)

head(df_bow)
# View the result
df_bat
unique(df_bat$Striker)


unique(df_bow$Bowler)

df_s

names(df_s)
head(df_s$Player)

bat = df_bat[df_bat$Season=='2023',]

bow = df_bow[df_bow$Season=='2023',]
head(bat )


dim(bow)
dim(df_s)


head(bat)
head(bow)

unique(df_s$Player)
unique(bat$Striker)
unique(bow$Bowler) 

# Load necessary library
library(dplyr)


# Perform a full join
joined_df <- full_join(bat, bow, by = c("Striker" = "Bowler"))

# Print the result
print(joined_df)
dim(joined_df)
write.csv(joined_df, 'joined_df.csv')
#HARMONISE THE NAMES IN THE TWO FILES

names(joined_df)
df = joined_df %>%
  select(Striker,Season.x,avg_runs,wicket)
View(df)

#To merge two files with sames names but differnt spellings

library(dplyr)
library(stringdist)

# Normalize the names
df$Striker <- tolower(trimws(df$Striker))
df_s$Player <- tolower(trimws(df_s$Player))


# Define a function to map names using fuzzy matching
match_names <- function(name, choices, threshold = 0.1) {
  distances <- stringdist::stringdist(name, choices, method = "jw")
  min_dist <- min(distances)
  if (min_dist <= threshold) {
    return(choices[which.min(distances)])
  } else {
    return(NA)
  }
}
# Create a list of choices from the second data frame
choices <- df_s$Player


# Apply the matching function to the first data frame
df <- df %>%
  mutate(matched_player = sapply(Striker, match_names, choices = choices ))

# Create a mapping dictionary if needed
name_mapping <- df %>%
  filter(!is.na(matched_player)) %>%
  select(Striker, matched_player)

# If needed, update the names in the original data frames
df<- df%>%
  mutate(Striker = ifelse(!is.na(matched_player), matched_player, Striker ))

df_s <- df_s%>%
  mutate(Player = ifelse(Player %in% name_mapping$matched_player, 
                         name_mapping$Striker[match(Player, name_mapping$matched_player)], 
                         Player))



# Ungroup the name_mapping to simplify the join
name_mapping <- name_mapping %>% ungroup()

# Perform a left join to safely replace player names
df_s <- df_s %>%
  left_join(name_mapping, by = c("Player" = "matched_player")) %>%
  mutate(Player = ifelse(is.na(Striker), Player, Striker)) %>%
  select(-Striker)

# Assuming df_s has already been processed
df_s <- df_s %>%
  left_join(name_mapping, by = c("Player" = "matched_player")) %>%
  mutate(Player = ifelse(is.na(Striker), Player, Striker)) %>%
  select(-Striker)

# Merge df_s with df using Player in df_s and Striker in df as keys
df_combined <- df_s %>%
  left_join(df, by = c("Player" = "Striker"))

# Print the resulting combined data frame
print(df_combined)
names(df_combined)
# Save the updated data frames if needed
write.csv(df_combined, 'df_combined.csv', row.names = FALSE)

max(df_combined$avg_runs, na.rm=TRUE)
max(df_combined$wicket, na.rm=TRUE)
890/28

quantile(df_combined$avg_runs, na.rm=TRUE,0.9)
quantile(df_combined$wicket, na.rm=TRUE,.9)

274/17.8  
# 15.5

df_combined$performance = df_combined$avg_runs+ 15.5*df_combined$wicket
any(is.na(df_combined$performance))
sum(is.na(df_combined$performance))

130+15.5*28


# Replace NA with 0 in the performance column
df_new <- df_combined %>%
  mutate(performance = ifelse(is.na(performance), 0, performance))

any(is.na(df_new$performance))

names(df_new)
str(df_new)

boxplot(df_new$performance)
df_new[df_new$performance<1,]
hist(df_new$performance, prob=TRUE)
lines(density(df_new$performance), na.rm=TRUE)

library(fitdistrplus)
descdist(df_new$performance)
head(df_new)
sum(is.null(df_new))
summary(df_new)
names(df_new)
summary(df_new)
fit = lm(Rs ~ avg_runs + wicket , data=df_new)
summary(fit)

library(car)
vif(fit)
library(lmtest)
bptest(fit)

fit1 = lm(Rs ~ avg_runs++wicket+  I(avg_runs*wicket), data=df_new)
summary(fit1)